
enum Env { djmote, pickupmvp, rapruler }

extension EnvData on Env {
  String port() {
    switch (this) {
      case Env.djmote:
        return '1337';
      case Env.pickupmvp:
        return '1340';
      case Env.rapruler:
        return '1339';
      default:
        return '1337';
    }
  }

  String get firebaseAppName => switch (this) {
    Env.pickupmvp => 'pickupmvp',
    Env.rapruler => 'rapruler',
    Env.djmote => 'djmote',
  };
}

Env fromFlavorToEnv(String flavor) {
  switch (flavor) {
    case 'pickupmvp':
      return Env.pickupmvp;
    case 'rapruler':
      return Env.rapruler;
    case 'djmote':
      return Env.djmote;
    default:

    /// you should do some default env
    /// for now, for test I am using djmote
      return Env.djmote;
  }
}
