import 'dart:math';

import 'package:flutter/material.dart';

class NimController {
  static final NimController _instance = NimController._internal();

  factory NimController() {
    return _instance;
  }

  NimController._internal();

  //0 hardest - 100 easiest
  int difficulty = 0;
  int currentPlayer = 1;
  bool playerVictory = false;
  bool gameRunning = false;
  List<List<int>> board = [[1], [1,1,1], [1,1,1,1,1], [1,1,1,1,1,1,1]];
  List<String> aiHistory = [];
  List<String> playerHistory = [];

  void resetGame() {
    difficulty = 0;
    currentPlayer = 1;
    playerVictory = false;
    gameRunning = false;
    board = [[1], [1,1,1], [1,1,1,1,1], [1,1,1,1,1,1,1]];
    aiHistory = [];
    playerHistory = [];
  }

  void setDifficulty(int difficulty) {
    this.difficulty = difficulty;
  }

  void changePlayer() {
    currentPlayer = currentPlayer == 1 ? 2 : 1;
  }

  bool isBalanced(List<List<int>> board) {
    var balanced = (board[0].reduce((value, element) => value + element) ^ board[1].reduce((value, element) => value + element)) ^ (board[2].reduce((value, element) => value + element) ^ board[3].reduce((value, element) => value + element));
    return balanced == 0;
  }

  void remove(List<List<int>> _board, int row, List<int> positions) {
    for (var position in positions) {
      _board[row][position] = 0;
    }
  }

  void checkWin() {
    for (var row in board) {
      if (row.reduce((value, element) => value + element) > 0) {
        changePlayer();
        return;
      }
    }

    if (currentPlayer == 1) {
      print('Player 1 Won!');
      playerVictory = true;
    } else {
      print('AI Won!');
      playerVictory = true;
    }

    gameRunning = false;
  }

  void aiMove() {
    List<int> tmp0 = List.from(board[0]);
    List<int> tmp1 = List.from(board[1]);
    List<int> tmp2 = List.from(board[2]);
    List<int> tmp3 = List.from(board[3]);
    List<List<int>> tempList = [tmp0, tmp1, tmp2, tmp3];
    //List<List<int>> tempList = List.from(board);
    bool foundBalanced = false;
    int rowTraversed = 0;

    if (Random().nextInt(101) > difficulty) {
      if (isBalanced(tempList)) {
        if (tempList[0].reduce((value, element) => value + element) > 0) {
          remove(tempList, 0, [tempList[0].indexOf(1)]);
          board = List.from(tempList);
        } else if (tempList[1].reduce((value, element) => value + element) > 0) {
          remove(tempList, 1, [tempList[1].indexOf(1)]);
          board = List.from(tempList);
        } else if (tempList[2].reduce((value, element) => value + element) > 0) {
          remove(tempList, 2, [tempList[2].indexOf(1)]);
          board = List.from(tempList);
        } else if (tempList[3].reduce((value, element) => value + element) > 0) {
          remove(tempList, 3, [tempList[3].indexOf(1)]);
          board = List.from(tempList);
        }
      } else {
        for (int row = 0; row < 4; row++) {
          int amount = 0;
          rowTraversed += 1;

          if (tempList[row].reduce((value, element) => value + element) > 0) {
            for (int v = 0; v < tempList[row].reduce((value, element) => value + element); v++) {
              remove(tempList, row, [tempList[row].indexOf(1)]);
              amount += 1;

              if (isBalanced(tempList)) {
                foundBalanced = true;
                String aiMoveMessage = 'AI removed: $amount From row: $rowTraversed';
                aiHistory.add(aiMoveMessage);
                board = List.from(tempList);
                return;
              }

              if (tempList[row].reduce((value, element) => value + element) == 0) {
                List<int> tmp0 = List.from(board[0]);
                List<int> tmp1 = List.from(board[1]);
                List<int> tmp2 = List.from(board[2]);
                List<int> tmp3 = List.from(board[3]);
                tempList = [tmp0, tmp1, tmp2, tmp3];
                //tempList = List.from(board);
              }
            }
            amount = 0;
          }
        }
      }

      //logLastMove('ai');
    } else {
      if (isBalanced(tempList)) {
        if (tempList[0].reduce((value, element) => value + element) > 0) {
          remove(tempList, 0, [tempList[0].indexOf(1)]);
          board = List.from(tempList);
        } else if (tempList[1].reduce((value, element) => value + element) > 0) {
          remove(tempList, 1, [tempList[1].indexOf(1)]);
          board = List.from(tempList);
        } else if (tempList[2].reduce((value, element) => value + element) > 0) {
          remove(tempList, 2, [tempList[2].indexOf(1)]);
          board = List.from(tempList);
        } else if (tempList[3].reduce((value, element) => value + element) > 0) {
          remove(tempList, 3, [tempList[3].indexOf(1)]);
          board = List.from(tempList);
        }
      }
    }
  }

  String drawGame() {
    String game = '';

    for (var row in board) {
      for (var value in row) {
        if (value == 1) {
          game += '1';
        } else {
          game += '0';
        }
      }
      game += '\n';
    }

    return game;
  }

  void startGame() {
    gameRunning = true;
  }

  void playerMove(int row, List<int> positions) {
    remove(board, row, positions);
    //logLastMove('player');
  }

  bool checkEndGame() {
    return gameRunning;
  }

}
