import 'package:flutter_riverpod/flutter_riverpod.dart';

// Modelo simple de usuario
class UserModel {
  final String? name;
  UserModel({this.name});

  UserModel copyWith({String? name}) {
    return UserModel(name: name ?? this.name);
  }
}

// StateNotifier para manejar el estado del usuario
class UserNotifier extends StateNotifier<UserModel> {
  UserNotifier() : super(UserModel());

  void setName(String newName) {
    state = state.copyWith(name: newName);
  }
}

// Provider global para el usuario
final userProvider = StateNotifierProvider<UserNotifier, UserModel>(
  (ref) => UserNotifier(),
);