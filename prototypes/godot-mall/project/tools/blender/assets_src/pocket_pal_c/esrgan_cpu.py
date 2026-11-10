"""Hybrid-route evidence: Real-ESRGAN (BSD-3) x4 upscale of a video-still crop on CPU, 2 threads.
Architectures re-declared here (weights from the project's GitHub releases) so no extra packages are needed."""
import sys, time, resource, torch, torch.nn as nn, torch.nn.functional as F, numpy as np, cv2
torch.set_num_threads(2)
class SRVGGNetCompact(nn.Module):
    def __init__(s, nf=64, nconv=32, up=4):
        super().__init__(); s.up = up
        b = [nn.Conv2d(3, nf, 3, 1, 1), nn.PReLU(nf)]
        for _ in range(nconv): b += [nn.Conv2d(nf, nf, 3, 1, 1), nn.PReLU(nf)]
        b += [nn.Conv2d(nf, 3 * up * up, 3, 1, 1)]
        s.body = nn.ModuleList(b); s.upsampler = nn.PixelShuffle(up)
    def forward(s, x):
        o = x
        for l in s.body: o = l(o)
        return s.upsampler(o) + F.interpolate(x, scale_factor=s.up, mode='nearest')
class RDB(nn.Module):
    def __init__(s, nf=64, gc=32):
        super().__init__()
        s.conv1 = nn.Conv2d(nf, gc, 3, 1, 1); s.conv2 = nn.Conv2d(nf + gc, gc, 3, 1, 1)
        s.conv3 = nn.Conv2d(nf + 2 * gc, gc, 3, 1, 1); s.conv4 = nn.Conv2d(nf + 3 * gc, gc, 3, 1, 1)
        s.conv5 = nn.Conv2d(nf + 4 * gc, nf, 3, 1, 1); s.l = nn.LeakyReLU(0.2, True)
    def forward(s, x):
        x1 = s.l(s.conv1(x)); x2 = s.l(s.conv2(torch.cat((x, x1), 1)))
        x3 = s.l(s.conv3(torch.cat((x, x1, x2), 1))); x4 = s.l(s.conv4(torch.cat((x, x1, x2, x3), 1)))
        return s.conv5(torch.cat((x, x1, x2, x3, x4), 1)) * 0.2 + x
class RRDB(nn.Module):
    def __init__(s): super().__init__(); s.rdb1, s.rdb2, s.rdb3 = RDB(), RDB(), RDB()
    def forward(s, x): return s.rdb3(s.rdb2(s.rdb1(x))) * 0.2 + x
class RRDBNet(nn.Module):
    def __init__(s, nf=64, nb=23):
        super().__init__()
        s.conv_first = nn.Conv2d(3, nf, 3, 1, 1); s.body = nn.Sequential(*[RRDB() for _ in range(nb)])
        s.conv_body = nn.Conv2d(nf, nf, 3, 1, 1); s.conv_up1 = nn.Conv2d(nf, nf, 3, 1, 1)
        s.conv_up2 = nn.Conv2d(nf, nf, 3, 1, 1); s.conv_hr = nn.Conv2d(nf, nf, 3, 1, 1)
        s.conv_last = nn.Conv2d(nf, 3, 3, 1, 1); s.l = nn.LeakyReLU(0.2, True)
    def forward(s, x):
        f = s.conv_first(x); f = f + s.conv_body(s.body(f))
        f = s.l(s.conv_up1(F.interpolate(f, scale_factor=2, mode='nearest')))
        f = s.l(s.conv_up2(F.interpolate(f, scale_factor=2, mode='nearest')))
        return s.conv_last(s.l(s.conv_hr(f)))
kind, wpath, src, out = sys.argv[1:5]
x0, y0, x1, y1 = map(int, sys.argv[5].split(','))
net = SRVGGNetCompact() if kind == 'general' else RRDBNet()
sd = torch.load(wpath, map_location='cpu', weights_only=True)
net.load_state_dict(sd.get('params_ema', sd.get('params', sd)), strict=True); net.eval()
img = cv2.imread(src)[y0:y1, x0:x1]
t = torch.from_numpy(img[..., ::-1].copy()).permute(2, 0, 1)[None].float() / 255
t0 = time.time()
with torch.inference_mode(): o = net(t)
dt = time.time() - t0
o = (o[0].clamp(0, 1).permute(1, 2, 0).numpy()[..., ::-1] * 255).round().astype(np.uint8)
cv2.imwrite(out, o)
cub = cv2.resize(img, None, fx=4, fy=4, interpolation=cv2.INTER_CUBIC)
cv2.imwrite(out.replace('.png', '_vs_bicubic.jpg'), np.hstack([cub, o]))
print(f"{kind} in={img.shape[1]}x{img.shape[0]} out={o.shape[1]}x{o.shape[0]} infer_s={dt:.1f} "
      f"peak_rss_mb={resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/1024:.0f}")
