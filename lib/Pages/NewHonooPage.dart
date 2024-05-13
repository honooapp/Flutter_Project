import 'package:flutter/material.dart';
import 'package:honoo/Utility/HonooColors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';


import '../Controller/DeviceController.dart';
import '../UI/HonooBuilder.dart';
import '../Utility/Utility.dart';
import 'package:sizer/sizer.dart';
import '../../Pages/ComingSoonPage.dart';

// import 'dart:async';
// // import 'package:flutter/material.dart';
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:googleapis_auth/auth_browser.dart';
// import 'package:http/http.dart' as http;

// class DriveUploader extends StatefulWidget {
//   @override
//   _DriveUploaderState createState() => _DriveUploaderState();
// }

// class _DriveUploaderState extends State<DriveUploader> {
//   final ClientId clientId = ClientId("Your-Client-Id", null); // No secret for web apps

//   Future<void> uploadFileToDrive() async {
//     var scopes = [drive.DriveApi.driveFileScope];
//     try {
//       var authClient = await obtainAccessCredentialsViaUserConsent(
//         clientId,
//         scopes,
//         http.Client(),
//         (url) {
//           // Prompt user to navigate to the URL
//           print('Please go to the following URL and grant access:');
//           print(url);
//         }
//       );
//       var driveApi = drive.DriveApi(authClient);
//       var fileToUpload = drive.File();
//       fileToUpload.name = 'Uploaded_by_Flutter_Web.txt';
//       var result = await driveApi.files.create(
//         fileToUpload,
//         uploadMedia: drive.Media(
//           Stream.value("Hello from Flutter!".codeUnits).asBroadcastStream(),
//           "Hello from Flutter!".length
//         ),
//       );
//       print('Uploaded file ID: ${result.id}');
//       authClient.close();
//     } catch (e) {
//       print('Error in uploading to Google Drive: $e');
//     }
//   }


class NewHonooPage extends StatefulWidget {
  const NewHonooPage({super.key});


  @override
  State<NewHonooPage> createState() => _NewHonooPageState();
}

class _NewHonooPageState extends State<NewHonooPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: HonooColor.background,
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: Center(
              child:Text(
                Utility().appName,
                style: GoogleFonts.libreFranklin(
                  color: HonooColor.secondary,
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: Container()),
              Container(
                constraints: DeviceController().isPhone() ? BoxConstraints(maxWidth: 100.w, maxHeight: 100.h - 60) : BoxConstraints(maxWidth: 50.w, maxHeight: 100.h - 60),
                child:Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 70.h,
                        child: const HonooBuilder(),
                      ),
                    ),
                    SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(icon: SvgPicture.asset(
                            "assets/icons/home.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            /*
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                            */
                            Navigator.pop(context);
                          }),
                          Padding(padding: EdgeInsets.only(left: 20.w),),
                          IconButton(icon: SvgPicture.asset(
                            "assets/icons/ok.svg",
                            semanticsLabel: 'Home',
                          ),
                          iconSize: 60,
                          splashRadius: 25,
                          onPressed: () {
                            // authenticateAndUpload();
                // would be nice to connect googledrive directly
                // HonooBuilder() must set a property or return user input to be sent to drive
                // follow below to connect drive
                // https://stackoverflow.com/questions/65784077/how-do-i-upload-a-file-to-google-drive-using-flutter

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ComingSoonPage(
                                  header: Utility().honooInsertTemporary,
                                  quote: Utility().shakespeare, bibliography:  Utility().bibliography,
                                )
                              ),
                            );

                          })
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ],
      ),
    );
  }
}
