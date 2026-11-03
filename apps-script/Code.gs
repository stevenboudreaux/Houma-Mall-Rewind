/* Southland Mall photo board: the back room.
   The game sends new pictures here. They are kept in pending/ in the GitHub repository until the owner approves them on
   review.html; approved ones move to photos/ and are listed in photos.json, which the game reads. An email goes to the owner
   for every submission.

   One-time setup (about five minutes):
     1. script.google.com > New project. Replace everything in Code.gs with this file.
     2. Fill in CONFIG below: the GitHub token (Contents: Read and write on this one repository), a passphrase of your own
        for ADMIN_KEY, and the email address that should get the notifications.
     3. Run > selfTest once. Google asks you to allow the script to reach the web and send mail as you. You should get a test
        email a moment later.
     4. Deploy > New deployment > type Web app > "Execute as: Me", "Who has access: Anyone" > Deploy. Copy the web app URL
        (ends in /exec) and paste it into index.html (PH_SUBMIT) and review.html (SUBMIT).
   To change the code later: paste the new version, then Deploy > Manage deployments > edit (pencil) > Version: New > Deploy,
   which keeps the same URL. */
var CONFIG={
  GITHUB_TOKEN:"PASTE_YOUR_GITHUB_TOKEN_HERE",
  REPO:"stevenboudreaux/Houma-Mall-Rewind",
  BRANCH:"main",
  ADMIN_KEY:"PICK_A_PASSPHRASE",
  NOTIFY_EMAIL:"steven_boudreaux@outlook.com",
  SITE:"https://stevenboudreaux.github.io/Houma-Mall-Rewind/"
};

function doGet(e){return out({ok:true,service:"southland-photos"});}
function doPost(e){
  var lock=LockService.getScriptLock();lock.waitLock(30000);
  try{
    var body=JSON.parse((e&&e.postData&&e.postData.contents)||"{}");
    if(body.action==="submit")return out(submit(body));
    if(body.action==="approve"||body.action==="deny"){
      if(!CONFIG.ADMIN_KEY||body.key!==CONFIG.ADMIN_KEY)return out({ok:false,error:"That passphrase isn't right."});
      return out(body.action==="approve"?approve(String(body.id||"")):deny(String(body.id||"")));
    }
    return out({ok:false,error:"unknown action"});
  }catch(err){return out({ok:false,error:String(err&&err.message||err)});}
  finally{lock.releaseLock();}
}
function out(o){return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);}

/* ---- GitHub contents API ---- */
function gh(method,path,payload){
  var url="https://api.github.com/repos/"+CONFIG.REPO+"/contents/"+path.split("/").map(encodeURIComponent).join("/");
  if(method==="GET")url+="?ref="+encodeURIComponent(CONFIG.BRANCH);
  var opt={method:method.toLowerCase(),headers:{Authorization:"Bearer "+CONFIG.GITHUB_TOKEN,Accept:"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28"},muteHttpExceptions:true};
  if(payload){opt.contentType="application/json";opt.payload=JSON.stringify(payload);}
  var r=UrlFetchApp.fetch(url,opt),code=r.getResponseCode();
  if(code===404&&method==="GET")return null;
  if(code>=300)throw new Error("GitHub "+code+" on "+method+" "+path+": "+r.getContentText().slice(0,160));
  return JSON.parse(r.getContentText()||"{}");
}
function readJson(path,fallback){var f=gh("GET",path);if(!f)return {sha:null,data:fallback};
  var txt=Utilities.newBlob(Utilities.base64Decode(String(f.content||"").replace(/\n/g,""))).getDataAsString("UTF-8");
  return {sha:f.sha,data:JSON.parse(txt||"null")||fallback};}
function writeJson(path,data,sha,msg){var b64=Utilities.base64Encode(Utilities.newBlob(JSON.stringify(data,null,1),"application/json").getBytes());
  var p={message:msg,content:b64,branch:CONFIG.BRANCH};if(sha)p.sha=sha;return gh("PUT",path,p);}
function clean(s,n){return String(s==null?"":s).replace(/[\u0000-\u001f]/g," ").trim().slice(0,n);}
function esc(s){return String(s).replace(/[&<>"]/g,function(c){return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c];});}

/* ---- a new picture from the game ---- */
function submit(b){
  var data=String(b.data||"").replace(/^data:image\/\w+;base64,/,"").replace(/\s/g,"");
  if(!data||data.length<100)throw new Error("The picture didn't arrive.");
  if(data.length>900000)throw new Error("That picture is too big. Try again; the game should shrink it first.");
  var store=clean(b.store,40).toLowerCase().replace(/[^a-z0-9]/g,"");if(!store)throw new Error("No store named.");
  var date=clean(b.date,24);if(date&&!/^\d{4}(-\d\d){0,2}( [a-z]+)?$/.test(date))date="";
  var id=Utilities.formatDate(new Date(),"UTC","yyyyMMddHHmmss")+Math.random().toString(36).slice(2,6);
  var entry={id:id,store:store,name:clean(b.name,60),file:"photos/"+store+"/"+id+".jpg",date:date,desc:clean(b.desc,500),by:clean(b.by,60),w:+b.w||0,h:+b.h||0,added:Date.now()};
  /* The submitter's email never goes in the repo: pending.json is a public file. It is kept in this script's private
     properties (for telling them later whether the photo was approved) and shown only in the notification email. */
  var email=clean(b.email,120);
  gh("PUT","pending/"+id+".jpg",{message:"Photo submitted for "+(entry.name||store),content:data,branch:CONFIG.BRANCH});
  var pj=readJson("pending.json",{v:1,pending:[]});pj.data.pending=pj.data.pending||[];pj.data.pending.push(entry);
  writeJson("pending.json",pj.data,pj.sha,"Queue a photo for review");
  if(email)PropertiesService.getScriptProperties().setProperty("email_"+id,email);
  notify(entry,data,email);
  return {ok:true,id:id};
}
/* The private email for a submission, removed once the decision is made. */
function takeEmail(id){var P=PropertiesService.getScriptProperties(),k="email_"+id,e=P.getProperty(k);if(e!=null)P.deleteProperty(k);return e||"";}
function notify(p,b64,email){
  try{
    var who=p.by||"Someone",link=CONFIG.SITE+"review.html#"+p.id;
    var html='<div style="font-family:system-ui,Arial,sans-serif;font-size:16px;line-height:1.5">'+
      '<p><b>'+esc(who)+'</b> posted a picture to the <b>'+esc(p.name||p.store)+'</b> board'+(p.date?', dated <b>'+esc(p.date)+'</b>':'')+'.</p>'+
      (p.desc?'<p style="padding:8px 12px;background:#f8e3ac;border-left:4px solid #a8672f">'+esc(p.desc)+'</p>':'')+
      (email?'<p>Their email (private, not on the review page): '+esc(email)+'</p>':'')+
      '<p><img src="cid:photo" style="max-width:480px;border:4px solid #5a3218"></p>'+
      '<p><a href="'+link+'" style="display:inline-block;padding:10px 18px;background:#f2c94c;color:#3b2230;font-weight:bold;text-decoration:none;border:3px solid #5a3218">Review it: approve or deny</a></p></div>';
    MailApp.sendEmail({to:CONFIG.NOTIFY_EMAIL,subject:"Southland Mall: new photo for "+(p.name||p.store)+" from "+who,htmlBody:html,
      inlineImages:{photo:Utilities.newBlob(Utilities.base64Decode(b64),"image/jpeg","photo.jpg")}});
  }catch(e){/* the submission is saved even when the email can't go out */}
}

/* ---- the owner's decision ---- */
function takePending(id){var pj=readJson("pending.json",{v:1,pending:[]});var L=pj.data.pending||[],i=-1;
  L.forEach(function(p,k){if(p.id===id)i=k;});if(i<0)throw new Error("That picture isn't in the review pile any more.");
  var p=L.splice(i,1)[0];pj.data.pending=L;return {p:p,pj:pj};}
function approve(id){
  /* Each step can be repeated safely, so an approval that stopped partway (for example when the owner was publishing
     at the same moment) can simply be pressed again. */
  var t=takePending(id),p=t.p,f=gh("GET","pending/"+id+".jpg");if(!f)throw new Error("The picture file is missing.");
  if(!gh("GET",p.file))gh("PUT",p.file,{message:"Approve a photo of "+(p.name||p.store),content:String(f.content||"").replace(/\n/g,""),branch:CONFIG.BRANCH});
  var ph=readJson("photos.json",{v:1,photos:[]});ph.data.photos=ph.data.photos||[];
  var pub={};["id","store","name","file","date","desc","by","w","h","added"].forEach(function(k){if(p[k]!=null&&p[k]!=="")pub[k]=p[k];});
  if(!ph.data.photos.some(function(q){return q.id===p.id;})){ph.data.photos.push(pub);writeJson("photos.json",ph.data,ph.sha,"Publish an approved photo of "+(p.name||p.store));}
  writeJson("pending.json",t.pj.data,t.pj.sha,"Photo approved");
  gh("DELETE","pending/"+id+".jpg",{message:"Clear a reviewed photo",sha:f.sha,branch:CONFIG.BRANCH});
  takeEmail(id);
  return {ok:true,photo:pub};
}
function deny(id){
  /* Delete the picture before taking it off the list, so a failure leaves it on the list to deny again rather than an orphan file. */
  var t=takePending(id),f=gh("GET","pending/"+id+".jpg");
  if(f)gh("DELETE","pending/"+id+".jpg",{message:"Remove a denied photo",sha:f.sha,branch:CONFIG.BRANCH});
  writeJson("pending.json",t.pj.data,t.pj.sha,"Photo denied");
  takeEmail(id);
  return {ok:true};
}

/* Run this once from the editor to grant permissions and check the connection. */
function selfTest(){
  var ph=readJson("photos.json",{v:1,photos:[]});
  Logger.log("GitHub reachable. "+(ph.data.photos||[]).length+" photos published.");
  MailApp.sendEmail(CONFIG.NOTIFY_EMAIL,"Southland Mall photo board is connected","Test email from your Apps Script. New photo submissions will arrive at this address.");
  Logger.log("Test email sent to "+CONFIG.NOTIFY_EMAIL);
}
