"""Body fields for cutting garments: scalar values on every skin vertex of a base body at neutral.

  y        height (m)
  arm      position along the arm, per side: 0 at the shoulder joint, 1 at the wrist, through the
           elbow at 0.5; negative into the torso (unclamped projection), so a sleeve cut at
           arm < L and a tank's armhole at arm < -0.02 are the same kind of cut
  leg      same along the leg: 0 at the hip joint, 0.5 knee, 1 ankle, > 1 the foot
  az       azimuth around the spine (degrees, 0 = front, +90 = the body's left), for necklines
  front    z relative to the spine (m), > 0 in front
Landmarks (heights): neck_base, chest (nipple line, female bust apex), waist, hip (widest), crotch.
"""
import numpy as np


class Fields:
    def __init__(self, R):
        self.R = R
        J = R.J
        v = R.v
        self.v = v
        self.J = J
        n = len(v)
        self.y = v[:, 1].copy()
        spine = J["mixamorig_Spine1"]
        self.az = np.degrees(np.arctan2(v[:, 0], v[:, 2] - spine[2]))
        self.front = v[:, 2] - spine[2]
        self.arm = np.full(n, -1.0)
        self.leg = np.full(n, -1.0)
        import body as bodymod
        RG = bodymod.REGIONS
        reg = np.array([RG[i] for i in R.reg[:n]])
        armish = np.isin(reg, ["shoulder_l", "shoulder_r", "upperarm_l", "upperarm_r", "forearm_l", "forearm_r", "hand_l", "hand_r"])
        legish = np.isin(reg, ["thigh_l", "thigh_r", "shin_l", "shin_r", "foot_l", "foot_r"])
        for s, sx in (("Left", 1), ("Right", -1)):
            side = v[:, 0] * sx > 0
            a = J["mixamorig_%sArm" % s]; e = J["mixamorig_%sForeArm" % s]; w = J["mixamorig_%sHand" % s]
            t = polyline_t(v[side], [a, e, w])
            # the torso only takes the negative side (armholes); arm verts the full parameter
            near_shoulder = self.y[side] > J["mixamorig_Spine1"][1]
            # torso: how far inside the shoulder joint, laterally, in arm units (0.5 = the upper
            # arm's length), so a tank's armhole is a clean line and the chest is never cut
            ua = np.linalg.norm(e - a) * 2
            lateral = (np.abs(v[side, 0]) - abs(a[0])) / ua
            self.arm[side] = np.where(armish[side], t, np.where(near_shoulder, np.minimum(lateral, -0.001), -1.0))
            h = J["mixamorig_%sUpLeg" % s]; k = J["mixamorig_%sLeg" % s]; f = J["mixamorig_%sFoot" % s]
            t = polyline_t(v[side], [h, k, f])
            near_hip = self.y[side] < J["mixamorig_Spine"][1]
            self.leg[side] = np.where(legish[side], t, np.where(near_hip, np.minimum(t, -0.001), -1.0))
        self.reg = reg
        # landmarks
        self.neck_base = J["mixamorig_Neck"][1] - 0.01
        torso = (np.abs(v[:, 0]) < 0.12) & (self.front > 0)
        band = torso & (self.y > J["mixamorig_Spine1"][1]) & (self.y < J["mixamorig_Neck"][1] - 0.05)
        self.chest = float(self.y[band][np.argmax(self.front[band])]) if band.any() else J["mixamorig_Spine2"][1]
        hj = float(J["mixamorig_Hips"][1])
        self.hips_joint = hj
        tor = np.isin(reg, ["chest_f", "chest_b", "belly_f", "belly_b", "pelvis_f", "pelvis_b", "crotch", "thigh_l", "thigh_r"])
        def width(y):
            m = tor & (np.abs(self.y - y) < 0.006)
            return np.abs(v[m, 0]).max() if m.any() else 0
        ys = np.arange(hj + 0.06, (hj + self.chest) / 2 + 0.02, 0.005)
        self.waist = float(ys[np.argmin([width(y) for y in ys])])           # narrowest
        ys = np.arange(hj - 0.09, hj + 0.04, 0.005)
        tor = np.isin(reg, ["pelvis_f", "pelvis_b", "crotch", "belly_f", "belly_b"])
        wd = [width(y) for y in ys]
        self.hip = float(ys[int(np.argmax(wd))])                             # widest
        self.hip_w = float(max(wd))
        inner = (np.abs(v[:, 0]) < 0.012) & (self.y > hj - 0.3) & (self.y < hj)
        self.crotch = float(self.y[inner].min()) if inner.any() else hj - 0.1
        self.hip_side = float(hj + 0.04)
        self.ankle = float(J["mixamorig_LeftFoot"][1])

        self.all = {"y": self.y, "arm": self.arm, "leg": self.leg, "az": self.az, "front": self.front, "x": v[:, 0]}

    def rise(self, f):
        """a waistband height: 0 = the hip joints, 1 = the natural (narrowest) waist"""
        return self.hips_joint + (self.waist - self.hips_joint) * f

    def at(self, P):
        """field values at arbitrary points: those of the nearest skin vertex"""
        _, _, idx = self.R.surface(P)
        return {k: a[idx] for k, a in self.all.items()}, idx


def polyline_t(P, pts):
    """unclamped parameter along a 2-segment polyline: [0, 0.5] first segment, [0.5, 1] second,
    < 0 before the start (projection on the first segment's line), > 1 past the end."""
    a, b, c = [np.asarray(x) for x in pts]
    ab = b - a; bc = c - b
    t1 = ((P - a) @ ab) / (ab @ ab)
    t2 = ((P - b) @ bc) / (bc @ bc)
    d1 = np.linalg.norm(P - (a + np.clip(t1, 0, 1)[:, None] * ab), axis=1)
    d2 = np.linalg.norm(P - (b + np.clip(t2, 0, 1)[:, None] * bc), axis=1)
    out = np.where(d1 <= d2, t1 * 0.5, 0.5 + t2 * 0.5)
    out = np.where((t1 < 0) & (d1 <= d2 + 0.02), t1 * 0.5, out)
    return out
