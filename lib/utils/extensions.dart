import 'package:gap/gap.dart';

extension GapInt on int {
  Gap get gap {
    return Gap(toDouble());
  }
}

extension GapDouble on double {
  Gap get  gap {
    return  Gap(this);
  }
}