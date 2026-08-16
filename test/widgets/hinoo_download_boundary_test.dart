import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Entities/hinoo.dart';
import 'package:honoo/Services/download_capture_service.dart';
import 'package:honoo/UI/hinoo_viewer.dart';

void main() {
  testWidgets('il download usa il canvas Hinoo e produce 1080x1920', (
    tester,
  ) async {
    GlobalKey? capturedKey;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 700,
            child: HinooViewer(
              draft: const HinooDraft(
                pages: [
                  HinooSlide(
                    backgroundImage: null,
                    text: 'Solo Hinoo',
                    isTextWhite: true,
                  ),
                ],
              ),
              maxHeight: 700,
              maxWidth: 390,
              authorId: 'test_user',
              viewerUserId: 'test_user',
              onDownloadCanvasTap: (key) => capturedKey = key,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('download'));
    await tester.pump();

    final boundary =
        capturedKey!.currentContext!.findRenderObject() as RenderBox;
    expect(boundary.size, const Size(360, 640));
    expect(DownloadCaptureService.pixelRatioForHeight(boundary.size.height), 3);
  });
}
