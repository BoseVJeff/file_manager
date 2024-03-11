import 'dart:async';

import 'package:ffi/ffi.dart';
import 'package:file_manager/providers/file_database_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:win32/win32.dart';
import 'dart:ffi';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    Logger.root.level = Level.ALL;
  } else {
    Logger.root.level = Level.INFO;
  }
  Logger.root.onRecord.listen((LogRecord record) {
    if (kDebugMode) {
      print(
        "${record.time.toIso8601String()} - ${record.loggerName} - ${record.level.name} - ${record.message}",
      );
    }
    // TODO: Deal with logs in production mode.
  });
  FileDatabaseProvider fileDatabaseProvider = FileDatabaseProvider();

  await fileDatabaseProvider.scanForFilesCompute(
      r"C:\Users\jeffb\Desktop\dev\flutter\file_manager\lib\", 1);

  // await fileDatabaseProvider
  //     .scanForFiles(r"C:\Users\jeffb\Desktop\dev\flutter\file_manager\lib\");

  // await compute<String, void>(
  //   (message) async {
  //     await fileDatabaseProvider.scanForFiles(message);
  //     return;
  //   },
  //   r"C:\Users\jeffb\Desktop\dev\flutter\file_manager\lib\",
  // );

  fileDatabaseProvider.dispose();

  // print(await launchUrl(Uri.parse(r"C:\Users\jeffb\Downloads\download.csv")));

  final lpSystemPowerStatus = calloc<SYSTEM_POWER_STATUS>();
  final hr = GetSystemPowerStatus(lpSystemPowerStatus);

  if (SUCCEEDED(hr)) {
    if (lpSystemPowerStatus.ref.BatteryFlag >= 128) {
      // This value is only less than 128 if a battery is detected.
      print('No system battery detected.');
    } else {
      final batteryRemainingPercent =
          lpSystemPowerStatus.ref.BatteryLifePercent;
      if (batteryRemainingPercent <= 100) {
        print('Battery detected with $batteryRemainingPercent% remaining.');
      } else {
        // Windows sets this value to 255 if it can't detect remaining life.
        print('Battery detected but status unknown.');
      }
    }
  }

  free(lpSystemPowerStatus);

  Pointer<SHFILEINFO> shfileinfo = calloc<SHFILEINFO>();

  final strPath = r"C:\Users\jeffb\Downloads\download.csv".toNativeUtf16();

  final res = SHGetFileInfo(
    strPath,
    0,
    shfileinfo,
    sizeOf<SHFILEINFO>(),
    // SHGFI_DISPLAYNAME
    0x000000200 +
        // SHGFI_ICON
        0x000000100,
  );

  // final ico = calloc<ICONINFO>();

  // int res2 = GetIconInfo(shfileinfo.ref.hIcon, ico);

  final bmp = calloc<BITMAP>();
  int res2 = GetObject(shfileinfo.ref.hIcon, sizeOf<BITMAP>(), bmp);

  print("Command returned with code $res");

  print("File display name: ${shfileinfo.ref.szDisplayName}");

  print("File icon handle pointer is ${shfileinfo.ref.hIcon}");

  print("File icon index is ${shfileinfo.ref.iIcon}");

  print("Size of BITMAP is ${sizeOf<BITMAP>()}");

  print("Icon is ${bmp.ref.bmWidth} X ${bmp.ref.bmHeight}");

  print("Icon is ${bmp.ref.bmBitsPixel} bits deep");

  // free(ico);

  free(bmp);

  DestroyIcon(shfileinfo.ref.hIcon);
  free(shfileinfo);
  free(strPath);

  return;
}
