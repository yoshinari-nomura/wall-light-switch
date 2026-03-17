include <BOSL2/std.scad>

// * Frame
//
// : <---------        36          --------->
// : +--------------------------------------+
// : |                                      |
// : |    +----------------------------+    | <|
// : |    |                            |    |  |
// : |    |            29              |    |  |
// : |    |<-------------------------->|    |  |
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    |                            |    |  | 43.25
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    |                            |    |  |
// : |    +----------------------------+    | <|
// : |                                      |
// : +--------------------------------------+
// + 厚さは，6mm
// + フレームの下をけずる:
// :                   29
// :     .------------------------------.    <|
// :    .                                .    |
// :   .                                  .   | 2mm
// :  +------------------------------------+ <|
// :                   30
//
module frame() {
  fs      = FRAME;                    // フレームの外形
  ps      = PANEL;                    // パネルの外形
  ss      = SWITCH;                   // フレームの内形 (=スイッチの外形)
  shaft_D = PANEL_SHAFT_D + m;        // 軸受穴の直径
  shaft_T = 2;                        // 軸受壁の厚さ
  shave   = [30, FRAME_BEZEL+e, 2+e]; // 手前ベゼルの下をけずる量
  bezel   = FRAME_BEZEL;              // ベゼルの厚さ

  // 軸受を 70度 の pie_slice で w=4 (PANEL.z) mm 切り取る
  // + 70度は，見た目と外れにくさの度合から適当な値を選定
  // + w はパネルの厚さと同じにしておくことで意図せず外れない
  // :
  // :      w/2
  // : B +-------+ A
  // :   |      /
  // :   |     /
  // : C +    /
  // :   |   /
  // :   |  /
  // :   | /
  // :   |/
  // :   D = 35度
  //
  // C は，軸受の中心，A は軸受の断面が描く円周上，つまり AC = d/2
  // B は 90度．CD (delta とする) を求めたい．
  //
  // BD = w/2/tan(35), BC = sqrt(CA^2 - (w/2)^2)
  // CD = w/2/tan(35) - sqrt( (d/2)^2 - (w/2)^2 )
  //
  function delta(d=shaft_D, w=ps.z, angle=70) =
    w/2/tan(angle/2) - sqrt( (d/2)^2 - (w/2)^2 );

  difference() {
    // フレーム外形
    cuboid(fs, rounding=R, edges=TOP) {
      up(fs.z/2) // シャフトが通る軸受の中心をフレームの上辺へ持ち上げる
        // シャフトが通る軸受の外形
        ycyl(d=shaft_D+shaft_T*2, h=fs.y, center=true);
    }

    // シャフトが入るように軸受の中を抜く
    up(fs.z/2)  // シャフトの中心をフレームの上辺へ
      ycyl(d=shaft_D, h=fs.y + e, center=true);

    // スイッチが入るようにフレーム外形の中を抜く．上下を X だけ増して確実に．
    cuboid(ss+[0,0,X]);

    // フレーム下側を削って受かせる
    translate([0, -(fs.y-bezel)/2, -((fs.z-shave.z)/2+e)])
      cuboid(shave);

    // 軸受の一方(奥)を pie_slice で削って切り掛きを入れる
    translate([0, (fs.y-bezel)/2, fs.z/2-delta()])
      pie_slice(ang=70, r=X, l=X, anchor=CENTER, orient=FRONT, spin=90-35);
  }
}

// * Panel
//   フレームに乗るパネル部分
//
module panel(anchor=CENTER, spin=0, orient=UP) {
  fs      = FRAME;          // フレームの外形
  hs      = PANEL_HORN;     // ホーンの外形
  ps      = PANEL;          // パネルの外形
  shaft_D = PANEL_SHAFT_D;  // シャフト直径
  shaft_L = FRAME.y + 1;    // シャフト長 (フレームから 1mm 首を出す)

  R2      = (R - ps.z) > 0 ? R - ps.z : 1;

  // attachable(anchor, spin, orient, cp=[0,-hs.y/2,0], size=hs) {
  attachable(anchor, spin, orient, size=ps) {
    recolor("green") difference() {
      // ホーン
      union() {
        fwd(-(fs.y/2+hs.y+(shaft_L-fs.y))) {
          front_half() difference() {
            cuboid([hs.x, hs.y*2, hs.z], rounding=R, edges="Z");
            cuboid([hs.x-ps.z*2, hs.y*2-ps.z*2, hs.z+X],
                   rounding=R2, edges="Z");
          }
        }
        // シャフト
        up((shaft_D - ps.z)/2) back((shaft_L - fs.y)/2)
          ycyl(d=shaft_D, h=shaft_L, center=true);

        // パネル
        cuboid(ps);
      }
      // シャフトの直径がパネルの厚さより大きい場合のために
      // パネル上面に出ているシャフトを削る
      up(ps.z) cuboid(ps+[0,X,0+e]);
    }
    children();
  }
}

$fn = 64;
m   = 0.5;
e   = 0.01;
X   = 30;    // 適度に大きい値
R   = 2;     // Rounding
H   = 2;     // 足を浮かせるために削る高さ

// | Name          | Value                                  |                |
// |---------------+----------------------------------------+----------------|
// | SPACER        | 2                                      |                |
// | SWITCH        | [29, 43.25, 0]                         |                |
// |---------------+----------------------------------------+----------------|
// | PANEL         | SWITCH + [-SPACER, -SPACER, 4]         | [27, 41.25, 4] |
// | PANEL_SHAFT_D | PANEL.z + 1                            | 5              |
// | PANEL_HORN    | [19, 10, PANEL.z]                      | [19, 10, 4]    |
// |---------------+----------------------------------------+----------------|
// | FRAME_BEZEL   | 3.5                                    |                |
// | FRAME         | SWITCH+[FRAME_BEZEL*2,FRAME_BEZEL*2,6] | [36, 50.25, 6] |
// |---------------+----------------------------------------+----------------|

// スイッチ
SPACER        = 2;
SWITCH        = [29, 43.25, 0];

// パネル
PANEL         = SWITCH + [-SPACER, -SPACER, 4];
PANEL_SHAFT_D = PANEL.z + 1;
PANEL_HORN    = [19, 10, PANEL.z];

// フレーム
FRAME_BEZEL   = 3.5;
FRAME         = SWITCH + [FRAME_BEZEL*2, FRAME_BEZEL*2, 6];

frame();
up(FRAME.z/2-0.5) panel();
