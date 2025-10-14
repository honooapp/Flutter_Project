import 'dart:io';
import 'dart:math';

class NimGame {
  int mode = 1;
  int difficulty = 0;
  int currentPlayer = 1;
  bool playerVictory = false;
  bool gameRunning = true;
  List<int> board = [1, 3, 5, 7];
  List<String> aiMovesHistory = [];
  List<String> playerMovesHistory = [];

  void clearConsole() {
    if (Platform.isWindows) {
      Process.runSync('cls', []);
    } else {
      Process.runSync('clear', []);
    }
  }

  void difficultySetup() {
    clearConsole();
    stdout.writeln('______');
    stdout.writeln('*Please choose % chance of winning (difficulty) level 0 - 100:');
    stdout.writeln('0 - Hardest');
    stdout.writeln('100 - Easiest');
    int choice = int.parse(stdin.readLineSync()!);

    if (choice < 0 || choice > 100) {
      stdout.writeln('Error! Only in the range 0-100 please!');
      difficultySetup();
    } else {
      difficulty = choice;
    }
  }

  void modeSetup() {
    stdout.writeln('______');
    stdout.writeln('**Please choose mode 1 or 2:');
    stdout.writeln('1 - vs AI');
    stdout.writeln('2 - vs Player');
    int choice = int.parse(stdin.readLineSync()!);

    if (choice < 1 || choice > 2) {
      stdout.writeln('Error! There are 2 modes!');
      modeSetup();
    } else {
      mode = choice;
      if (choice == 1) {
        difficultySetup();
      }
    }
  }

  void changePlayer() {
    currentPlayer = currentPlayer == 1 ? 2 : 1;
  }

  void logLastMove(String target) {
    if (target == 'ai') {
      if (aiMovesHistory.isNotEmpty) {
        stdout.writeln('033[1;32;40m${aiMovesHistory.last}');
        stdout.writeln('033[1;37;40m');
      }
    } else {
      if (playerMovesHistory.isNotEmpty) {
        stdout.writeln(playerMovesHistory.last);
      }
    }
  }

  bool isBalanced(List<int> boardToCheck) {
    int balanced = (boardToCheck[0] ^ boardToCheck[1]) ^
        (boardToCheck[2] ^ boardToCheck[3]);
    return balanced == 0;
  }

  void drawGame(List<int> boardToCheck) {
    int count = 1;

    for (int el in boardToCheck) {
      stdout.write('$count: ');
      count++;

      for (int i = 0; i < el; i++) {
        stdout.write(' O ');
      }

      stdout.writeln('');
    }

    stdout.writeln('');

    // stdout.writeln('Balanced: ', isBalanced(boardToCheck));
  }

  int getCorrectRow() {
    stdout.write('--> Row to remove from: ');
    int row = int.parse(stdin.readLineSync()!);

    if (row < 1 || row > 4) {
      stdout.writeln('Error! There are 4 rows!');
      return getCorrectRow();
    } else {
      if (board[row - 1] < 1) {
        stdout.writeln('Error! That row is empty!');
        return getCorrectRow();
      } else {
        return row - 1;
      }
    }
  }

  int getCorrectAmount(int row) {
    stdout.write('--> Amount to remove: ');
    int amount = int.parse(stdin.readLineSync()!);

    if (amount < 1 || amount > board[row]) {
      stdout.writeln('Error! Illegal amount!');
      return getCorrectAmount(row);
    } else {
      return amount;
    }
  }

  void remove() {
    stdout.writeln('Player $currentPlayer\'s turn!');
    drawGame(board);

    int row = getCorrectRow();
    int amount = getCorrectAmount(row);

    board[row] -= amount;

    String playerMoveMessage = 'Player removed: $amount From row: ${row + 1}';
    playerMovesHistory.add(playerMoveMessage);
  }

  void checkWin() {
    for (int value in board) {
      if (value > 0) {
        changePlayer();
        return;
      }
    }

    stdout.writeln('----------------------------');
    if (currentPlayer == 1) {
      stdout.writeln('Player 1 Won!');
    } else {
      if (mode == 1) {
        stdout.writeln('AI Won!');
      } else {
        stdout.writeln('Player 2 Won!');
      }
    }
    stdout.writeln('----------------------------');

    gameRunning = false;
  }

  void aiMove() {
    List<int> tempList = List.from(board);
    bool foundBalanced = false;
    int rowTraversed = 0;

    if (Random().nextInt(101) > difficulty) {
      if (isBalanced(tempList)) {
        if (tempList[0] > 0) {
          tempList[0] -= 1;
          board = List.from(tempList);
        } else if (tempList[1] > 0) {
          tempList[1] -= 1;
          board = List.from(tempList);
        } else if (tempList[2] > 0) {
          tempList[2] -= 1;
          board = List.from(tempList);
        } else if (tempList[3] > 0) {
          tempList[3] -= 1;
          board = List.from(tempList);
        }
      } else {
        for (int row = 0; row < 4; row++) {
          int amount = 0;
          rowTraversed += 1;

          if (tempList[row] > 0) {
            for (int v = 0; v < tempList[row]; v++) {
              tempList[row] -= 1;
              amount += 1;

              if (isBalanced(tempList)) {
                foundBalanced = true;
                String aiMoveMessage =
                    'AI removed: $amount From row: $rowTraversed';
                aiMovesHistory.add(aiMoveMessage);
                board = List.from(tempList);
                break;
              }

              if (tempList[row] == 0) {
                tempList = List.from(board);
              }
            }
          }

          if (foundBalanced) {
            break;
          }

          amount = 0;
        }
      }

      logLastMove('ai');
    } else {
      if (isBalanced(tempList)) {
        if (tempList[0] > 0) {
          tempList[0] -= 1;
          board = List.from(tempList);
        } else if (tempList[1] > 0) {
          tempList[1] -= 1;
          board = List.from(tempList);
        } else if (tempList[2] > 0) {
          tempList[2] -= 1;
          board = List.from(tempList);
        } else if (tempList[3] > 0) {
          tempList[3] -= 1;
          board = List.from(tempList);
        }
      }
    }
  }

  void playGame() {
    // ------------------------------------
    // GAME START
    // ------------------------------------

    // Choose the mode
    modeSetup();

    // Draw the initial board
    if (mode == 1) {
      // vs AI setup
      while (gameRunning) {
        if (currentPlayer == 1) {
          remove();
        } else {
          clearConsole();
          aiMove();
        }

        checkWin();
      }
    } else {
      // 2 player mode setup
      while (gameRunning) {
        if (currentPlayer == 1) {
          remove();
        } else {
          clearConsole();
          remove();
        }

        checkWin();
      }
    }
  }
}

void main() {
  NimGame nimGame = NimGame();
  nimGame.playGame();
}
