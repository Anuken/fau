import common

var quadv: array[24, GLfloat]

for v in quadv.mitems: v = 0.0

proc fillQuad*(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4: float32) = 
  quadv[0] = x1
  quadv[1] = y1
  quadv[4] = c1

  quadv[6] = x2
  quadv[7] = y2
  quadv[10] = c2

  quadv[12] = x2
  quadv[13] = y2
  quadv[16] = c2

  quadv[18] = x2
  quadv[19] = y2
  quadv[22] = c2

  drawVert(fuse.whiteTex, quadv)
#[
public static void line(TextureRegion region, float x, float y, float x2, float y2, CapStyle cap, float padding){
  float length = Mathf.dst(x, y, x2, y2) + (cap == CapStyle.none || cap == CapStyle.round ? padding * 2f : stroke + padding * 2);
  float angle = (precise ? (float)Math.atan2(y2 - y, x2 - x) : Mathf.atan2(x2 - x, y2 - y)) * Mathf.radDeg;

  if(cap == CapStyle.square){
      Draw.rect(region, x - stroke / 2 - padding + length/2f, y, length, stroke, stroke / 2 + padding, stroke / 2, angle);
  }else if(cap == CapStyle.none){
      Draw.rect(region, x - padding + length/2f, y, length, stroke, padding, stroke / 2, angle);
  }else if(cap == CapStyle.round){ //TODO remove or fix
      TextureRegion cir = Core.atlas.has("hcircle") ? Core.atlas.find("hcircle") : Core.atlas.find("circle");
      Draw.rect(region, x - padding + length/2f, y, length, stroke, padding, stroke / 2, angle);
      Draw.rect(cir, x, y, stroke, stroke, angle + 180f);
      Draw.rect(cir, x2, y2, stroke, stroke, angle);
  }
}
]#