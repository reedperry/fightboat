const rows = {
  'A': 0,
  'B': 1,
  'C': 2,
  'D': 3,
  'E': 4,
  'F': 5,
  'G': 6,
  'H': 7,
  'I': 8,
  'J': 9
};

const columnCount = 10;

/// Players in the game
enum Player { one, two }

/// Possible status for a space on the board
enum Status { boat, empty, hit, miss }

class Game {
  bool started;
  Board board1;
  Board board2;
  Player currentPlayerTurn;

  Game() {
    started = false;
    board1 = Board();
    board2 = Board();
  }

  bool isSetUp() {
    return !started &&
        board1.getBoats().length == 5 &&
        board2.getBoats().length == 5;
  }

  void addBoat(Boat boat, Player player) {
    if (player == Player.one) {
      board1.addBoat(boat);
    } else if (player == Player.two) {
      board2.addBoat(boat);
    }
  }

  void startGame() {
    if (isSetUp()) {
      started = true;
      currentPlayerTurn = Player.one;
    }
  }

  void doTurn(Coords target) {
    if (currentPlayerTurn == Player.one) {
      board2.addShot(target);
      currentPlayerTurn = Player.two;
    } else {
      board1.addShot(target);
      currentPlayerTurn = Player.one;
    }
  }

  bool isOver() {
    return started && (board1.areAllBoatsSunk() || board2.areAllBoatsSunk());
  }

  Player getWinner() {
    if (!started) return null;

    if (board1.areAllBoatsSunk()) {
      return Player.two;
    } else if (board2.areAllBoatsSunk()) {
      return Player.one;
    } else {
      return null;
    }
  }

  @override
  String toString() {
    return '''Game:
    Started: $started
    Current Player Turn: $currentPlayerTurn
    Game Over: ${isOver()}
    Winner: ${getWinner()}
    Board 1: $board1
    Board 2: $board2''';
  }
}

class Board {
  List<Shot> _shots;
  List<Boat> _boats;

  Board() {
    _boats = [];
    _shots = [];
  }

  List<Boat> getBoats() {
    return this._boats;
  }

  List<Shot> getShots() {
    return this._shots;
  }

  void addBoat(Boat boat) {
    _boats.add(boat);
  }

  void addShot(Coords coords) {
    if (isShotAtCoords(coords)) {
      throw Exception('A shot is already present at $coords');
    }

    var boat = getBoatAtCoords(coords);
    if (boat != null) {
      boat.hitAt(coords);
      _shots.add(Shot(coords, Status.hit));
    } else {
      _shots.add(Shot(coords, Status.miss));
    }
  }

  Boat getBoatAtCoords(Coords coords) {
    for (var boat in _boats) {
      if (boat.getLocations().any((location) => location == coords)) {
        return boat;
      }
    }
    return null;
  }

  bool isShotAtCoords(Coords coords) {
    return _shots.any((shot) => shot.coords == coords);
  }

  bool areAllBoatsSunk() {
    return _boats.every((boat) => boat.isSunk());
  }

  @override
  String toString() {
    return '''Board:
    Boats: $_boats
    Shots: $_shots''';
  }
}

class Boat {
  Set<Coords> _locations;
  Set<Coords> _hits;

  Boat(List<Coords> coords) {
    validateCoords(coords);
    _locations = Set.from(coords);
    _hits = {};
  }

  Boat.fromRange(Coords start, Coords end) {
    final coords = convertCoordsRangeToList(start, end);
    // Can we call the default constructor here instead?
    validateCoords(coords);
    _locations = Set.from(coords);
    _hits = {};
  }

  List<Coords> getLocations() {
    return _locations.toList();
  }

  void hitAt(Coords coords) {
    _hits.add(coords);
  }

  void validateCoords(List<Coords> coords) {
    if (coords.length < 2 || coords.length > 5) {
      throw Exception('Illegal boat length: {$coords.length}');
    }
    if (coords.length != Set.from(coords).length) {
      throw Exception(
          'Illegal boat positioning. Duplicate coordinates occupied.');
    }

    List<int> columns = List.from(coords.map((coord) => coord.col));
    List<int> rows = List.from(coords.map((coord) => coord.row));
    var isVertical = Set.from(columns).length == 1;
    var isHorizontal = Set.from(rows).length == 1;
    if (!isVertical && !isHorizontal) {
      throw Exception(
          'Non-linear boat positioning. Must occupy either one column or one row.');
    }

    // Verify that the coordinates are consecutive.
    // There's probably a more elegant way to do this.
    if (isHorizontal) {
      columns.sort();
      for (var i = 1; i < columns.length; i++) {
        if (columns[i - 1] + 1 != columns[i]) {
          throw Exception(
              'Boat does not occupy consecutive spaces - gap from column ${columns[i - 1]} to ${columns[i]}');
        }
      }
    } else if (isVertical) {
      rows.sort();
      for (var i = 1; i < rows.length; i++) {
        if (rows[i - 1] + 1 != rows[i]) {
          throw Exception(
              'Boat does not occupy consecutive spaces - gap from row ${rows[i - 1]} to ${rows[i]}');
        }
      }
    }
  }

  bool isSunk() {
    return _locations.difference(this._hits).isEmpty;
  }

  @override
  String toString() {
    return 'Boat ${isSunk() ? "[SUNK]" : ""} at $_locations - hit at $_hits';
  }
}

/// Coords represents a row/column pair for a single location on the board
class Coords {
  int row, col;

  Coords(row, col) {
    if (row >= 0 && row < 10 && col >= 0 && col < 10) {
      this.row = row;
      this.col = col;
    } else {
      throw Exception('Invalid Coords: row: $row, column: $col');
    }
  }

  @override
  int get hashCode {
    int result = 17;
    result = 37 * result + row;
    result = 37 * result + col;
    return result;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Coords) return false;
    Coords coords = other;
    return coords.row == row && coords.col == col;
  }

  @override
  String toString() {
    return '[${this.row}, ${this.col}]';
  }
}

/// Shot represents a single shot displayed on the board
class Shot {
  Coords coords;
  Status status;

  Shot(this.coords, this.status);

  @override
  String toString() {
    return 'Shot [$status] at $coords';
  }
}

class BoardOverlay {
  List<List<Status>> spaces;

  BoardOverlay.fromShots(List<Shot> shots) {
    var row = List.filled(10, Status.empty);
    var grid = List<List<Status>>(10);
    for (var i = 0; i < rows.keys.length; i++) {
      grid[i] = List.from(row);
    }

    for (var shot in shots) {
      grid[shot.coords.row][shot.coords.col] = shot.status;
    }

    this.spaces = grid;
  }

  BoardOverlay.fromBoats(List<Boat> boats) {
    var row = List.filled(10, Status.empty);
    var grid = List<List<Status>>(10);
    for (var i = 0; i < rows.keys.length; i++) {
      grid[i] = List.from(row);
    }

    for (var boat in boats) {
      for (var space in boat._locations) {
        grid[space.row][space.col] = Status.boat;
      }
    }

    this.spaces = grid;
  }
}

List<Coords> convertCoordsRangeToList(Coords start, Coords end) {
  if (start == end) {
    throw Exception('Start and end coordinates of a range must be different');
  }
  var list = [start, end];
  if (start.col == end.col) {
    for (var i = 1; i < end.row - start.row; i++) {
      list.insert(i, Coords(start.row + i, start.col));
    }
  } else if (start.row == end.row) {
    for (var i = 1; i < end.col - start.col; i++) {
      list.insert(i, Coords(start.row, start.col + i));
    }
  }

  return list;
}
