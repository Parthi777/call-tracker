import 'package:freezed_annotation/freezed_annotation.dart';

part 'executive.freezed.dart';
part 'executive.g.dart';

@freezed
abstract class Executive with _$Executive {
  const factory Executive({
    required String id,
    required String name,
    required String phone,
    String? driveFolder,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _Executive;

  factory Executive.fromJson(Map<String, dynamic> json) =>
      _$ExecutiveFromJson(json);
}
