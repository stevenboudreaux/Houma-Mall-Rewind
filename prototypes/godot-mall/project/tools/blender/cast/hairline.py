"""The scalp hair of a short style as a density field on the head (shared by the painted scalp in the
skin texture and the hair shell), in a head frame:

  c   head centre: between the ears, 2 cm above the eyes, 8.5 cm behind them
  az  azimuth around the vertical, 0 = straight ahead, + toward the person's left (+X)
  el  elevation from c's horizontal plane (degrees)

A style's hairline is an elevation per |azimuth| (piecewise linear, symmetric unless `part_shift`);
density is 1 above it, fading over `soft` degrees. `fade` lowers the painted density on the sides and
back below a second line (a fade / taper cut). Everything is in the person's data file.
"""
import numpy as np

# default hairline (|az| degrees, el degrees): forehead, temples, sideburns, over the ears, nape
LINE = [(0, 36), (25, 37), (45, 35), (62, 26), (76, 6), (84, -16), (92, -14), (97, 0), (108, 2),
        (125, -6), (150, -24), (180, -40)]


class Hair:
    def __init__(self, person, spec):
        self.spec = spec or {}
        J = person.J
        eyes = 0.5 * (J["eye.L"] + J["eye.R"])
        self.c = np.array([0.0, eyes[1] + 0.02, eyes[2] - 0.085])
        line = self.spec.get("line", LINE)
        adj = self.spec.get("line_adjust", {})
        pts = [(a, e + float(adj.get(str(a), 0))) for a, e in line]
        self.la = np.array([p[0] for p in pts], float)
        self.le = np.array([p[1] for p in pts], float) + float(self.spec.get("line_shift", 0.0))
        self.soft = float(self.spec.get("soft", 3.0))
        self.fade = self.spec.get("fade")          # {"lo": el, "hi": el, "min": density}

    def frame(self, p):
        v = np.asarray(p) - self.c
        r = np.linalg.norm(v, axis=-1)
        az = np.degrees(np.arctan2(v[..., 0], v[..., 2]))
        el = np.degrees(np.arcsin(np.clip(v[..., 1] / np.maximum(r, 1e-9), -1, 1)))
        return az, el, r

    def line(self, az):
        return np.interp(np.abs(az), self.la, self.le)

    def density(self, p):
        az, el, _ = self.frame(p)
        L = self.line(az)
        t = np.clip((el - (L - self.soft)) / (2 * self.soft), 0, 1)
        return t * t * (3 - 2 * t)

    def signed(self, p):
        """Degrees above the hairline (a smooth field: the shell is cut along it)."""
        az, el, _ = self.frame(p)
        return el - self.line(az)

    def paint_density(self, p):
        """Density of the painted scalp (the fade thins the sides and back)."""
        d = self.density(p)
        if self.fade:
            az, el, _ = self.frame(p)
            lo, hi, mn = float(self.fade["lo"]), float(self.fade["hi"]), float(self.fade.get("min", 0.35))
            side = np.clip((np.abs(az) - 40) / 40, 0, 1)        # front stays full
            t = np.clip((el - lo) / max(hi - lo, 1e-6), 0, 1)
            d = d * (1 - side * (1 - (mn + (1 - mn) * t)))
        return d

    def thickness(self, p):
        """Shell offset (metres) for the volume of the cut: thick on top, thin on the sides."""
        az, el, _ = self.frame(p)
        top = float(self.spec.get("top_mm", 6)) / 1000
        side = float(self.spec.get("side_mm", 2.5)) / 1000
        front = float(self.spec.get("front_mm", top * 1000)) / 1000
        t = np.clip((el - 5) / 45, 0, 1)
        th = side + (top - side) * t
        f = np.clip(np.cos(np.radians(az)), 0, 1) * np.clip((el - 20) / 30, 0, 1)
        th = th + (front - top) * f * t
        part = self.spec.get("part_az")
        if part is not None:
            # a side part: a groove from the front hairline toward the crown, fuller on the far side
            pa = float(part)
            g = np.exp(-((az - pa) / 5.0) ** 2) * np.clip((el - 25) / 10, 0, 1) * np.clip((78 - el) / 10, 0, 1)
            th = th * (1 - 0.75 * g)
            sweep = np.clip(-(az - pa) * np.sign(pa) / 40, 0, 1) * np.clip((el - 25) / 20, 0, 1)
            th = th + 0.003 * sweep
        if self.fade:
            lo, hi = float(self.fade["lo"]), float(self.fade["hi"])
            sidef = np.clip((np.abs(az) - 40) / 40, 0, 1)
            k = np.clip((el - lo) / max(hi - lo, 1e-6), 0, 1)
            th = th * (1 - sidef * (1 - (0.25 + 0.75 * k)))
        return th
