import 'package:flutter/painting.dart';

/// Coordinates measured on the approved photograph, never a rotated template.
/// The printed numbers belong to the image; indices are unique game positions.
class JackarooBoardLayout {
  static const asset = 'assets/images/jackaroo_reference_board.png';
  static const referenceSize = Size(1232, 1277);
  static const trackLength = 76;
  static const sectionLength = 19;
  static const spawnSlots = [0, 57, 38, 19]; // blue, green, black, sky

  // Clockwise: blue -> sky -> black -> green -> blue.
  // Each section starts with an unnumbered colored point, then 1 through 18.
  static const track = <Offset>[
    Offset(537, 1066),
    Offset(535, 1013),
    Offset(535, 969),
    Offset(535, 926),
    Offset(535, 883),
    Offset(535, 842),
    Offset(502, 809),
    Offset(470, 776),
    Offset(436, 742),
    Offset(405, 709),
    Offset(371, 677),
    Offset(322, 677),
    Offset(272, 677),
    Offset(222, 677),
    Offset(172, 677),
    Offset(121, 677),
    Offset(121, 635),
    Offset(121, 593),
    Offset(121, 550),
    Offset(122, 507),
    Offset(173, 507),
    Offset(223, 507),
    Offset(273, 507),
    Offset(323, 507),
    Offset(372, 507),
    Offset(419, 477),
    Offset(452, 445),
    Offset(485, 415),
    Offset(517, 384),
    Offset(544, 350),
    Offset(544, 309),
    Offset(544, 268),
    Offset(544, 227),
    Offset(544, 186),
    Offset(544, 142),
    Offset(591, 142),
    Offset(635, 142),
    Offset(681, 142),
    Offset(721, 141),
    Offset(719, 187),
    Offset(718, 227),
    Offset(718, 268),
    Offset(718, 309),
    Offset(718, 350),
    Offset(747, 385),
    Offset(779, 416),
    Offset(812, 447),
    Offset(845, 479),
    Offset(884, 507),
    Offset(931, 507),
    Offset(976, 507),
    Offset(1023, 507),
    Offset(1068, 507),
    Offset(1115, 507),
    Offset(1115, 551),
    Offset(1115, 594),
    Offset(1115, 636),
    Offset(1117, 678),
    Offset(1069, 677),
    Offset(1023, 677),
    Offset(976, 677),
    Offset(929, 677),
    Offset(882, 677),
    Offset(846, 712),
    Offset(814, 745),
    Offset(781, 777),
    Offset(749, 809),
    Offset(717, 842),
    Offset(715, 884),
    Offset(715, 926),
    Offset(715, 970),
    Offset(715, 1013),
    Offset(719, 1067),
    Offset(675, 1067),
    Offset(630, 1067),
    Offset(585, 1067),
  ];

  // Outside -> inside in each player's home lane.
  static const safe = <List<Offset>>[
    [Offset(630, 1014), Offset(630, 970), Offset(630, 926), Offset(630, 882)],
    [Offset(1065, 594), Offset(1018, 594), Offset(971, 594), Offset(925, 594)],
    [Offset(630, 186), Offset(630, 227), Offset(630, 267), Offset(630, 307)],
    [Offset(173, 593), Offset(223, 593), Offset(272, 593), Offset(321, 593)],
  ];

  static const home = <List<Offset>>[
    [Offset(315, 916), Offset(364, 916), Offset(315, 964), Offset(364, 964)],
    [Offset(895, 949), Offset(944, 949), Offset(895, 997), Offset(944, 997)],
    [Offset(838, 209), Offset(883, 209), Offset(837, 251), Offset(883, 252)],
    [Offset(245, 394), Offset(291, 394), Offset(245, 438), Offset(292, 438)],
  ];
  static const dishes = [
    Offset(339, 941),
    Offset(920, 974),
    Offset(860, 233),
    Offset(267, 417),
  ];
  static const dishRadii = [61.0, 61.0, 57.0, 57.0];
  static const marbleRadii = [22.0, 22.0, 21.0, 21.0];
  static const playerNames = ['الأزرق', 'الأخضر', 'الأسود', 'السماوي'];

  static int? numberAt(int index) =>
      index % sectionLength == 0 ? null : index % sectionLength;

  static Rect fittedRect(Size viewport) {
    final fitted = applyBoxFit(BoxFit.contain, referenceSize, viewport);
    return Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & viewport,
    );
  }

  static int gateFor(int owner) => (spawnSlots[owner] - 2) % trackLength;

  /// One point per actual step, including the turn into a home lane.
  /// Overshooting the lane is illegal, rather than wrapping onto the track.
  static List<JackarooPathStep>? route({
    required int owner,
    required int position,
    required int steps,
    bool inSafe = false,
  }) {
    if (steps == 0 || (inSafe && steps < 0)) return null;
    final result = <JackarooPathStep>[];
    var slot = position;
    var safeLane = inSafe;
    for (var i = 0; i < steps.abs(); i++) {
      if (steps < 0) {
        slot = (slot - 1) % trackLength;
      } else if (safeLane) {
        if (++slot >= 4) return null;
      } else if (slot == gateFor(owner)) {
        safeLane = true;
        slot = 0;
      } else {
        slot = (slot + 1) % trackLength;
      }
      result.add(JackarooPathStep(slot, inSafe: safeLane));
    }
    return result;
  }
}

class JackarooPathStep {
  final int index;
  final bool inSafe;
  const JackarooPathStep(this.index, {this.inSafe = false});

  Offset pointFor(int owner) => inSafe
      ? JackarooBoardLayout.safe[owner][index]
      : JackarooBoardLayout.track[index];
}
