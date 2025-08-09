import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'package:xprinter2/bluetooth_connection_screen.dart';
import 'package:xprinter2/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPrinterConnected = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  int? imageWidth;
  int? imageHeight;

  String? _base64Image;
  final pageWidth = 565.00;
  // BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;

  // @override
  // void initState() {
  //   // Listen for changes in the Bluetooth adapter state
  //   FlutterBluePlus.adapterState.listen((state) {
  //     log('Bluetooth state changed: ${state.name}');
  //     setState(() {
  //       _bluetoothState = state;
  //     });
  //   });
  //   Future.delayed(Duration.zero, () async {
  //     final bluetoothState = await FlutterBluePlus.adapterState.first;

  //     if (bluetoothState == BluetoothAdapterState.off) {
  //       log('Bluetooth is off, attempting to turn it on...');
  //       _turnBluetoothOn();
  //     } else {
  //       log('Bluetooth is already on: ${bluetoothState.name}');
  //     }
  //   });
  //   super.initState();
  // }

  // Future<void> _checkBluetoothState() async {
  //   final state = await FlutterBluePlus.adapterState.first;
  //   setState(() {
  //     _bluetoothState = state;
  //   });
  // }

  // Future<void> _turnBluetoothOn() async {
  //   // Request the user to turn on Bluetooth.
  //   // On Android, this will usually show a system dialog.
  //   // On iOS, it will typically direct the user to settings if off.
  //   await FlutterBluePlus.turnOn();
  //   // _checkBluetoothState(); // Recheck state after attempting to turn on
  // }

  @override
  void initState() {
    plugin.statusStream.listen((status) {
      log('Printer status: ${status.status}');
    });

    Future.delayed(Duration.zero, () async {
      final isConnected = await plugin.isConnected;
      log(
        'Is printer connected---------------------------------------------: $isConnected',
      );
      if (isConnected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _screenshotController
              .captureFromLongWidget(
                InheritedTheme.captureAll(
                  context,
                  Material(child: myLongWidget),
                ),
                delay: const Duration(milliseconds: 200), // Increased delay
                context: context,
                // pixelRatio: 0.5,
                constraints: BoxConstraints(
                  maxWidth: pageWidth,
                  maxHeight: 30000, // Allow sufficient height
                ),
              )
              .then((capturedImage) async {
                final img.Image? decodedImage = img.decodeImage(capturedImage);
                if (decodedImage == null) {
                  log('Failed to decode image');
                  return false;
                }
                log(
                  "image width: ${decodedImage.width}, height: ${decodedImage.height}",
                );
                imageWidth = decodedImage.width;
                imageHeight = decodedImage.height;

                final kbSize = decodedImage.length / 1028;

                log("Kb Size: $kbSize");

                // setState(() {
                //   _imageFile = capturedImage;
                // });
                _base64Image = base64Encode(capturedImage);

                final isConnected = await plugin.isConnected;
                if (!isConnected) {
                  log('Printer is not connected');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Printer is not connected')),
                    );
                  });

                  return false;
                }

                setState(() {});
              });
        });
      }
      log('Printer is connected: $isConnected');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log('Building HomeScreen=> ${MediaQuery.of(context).size.width}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BluetoothConnectionScreen(),
                ),
              );

              if (result != null && result is String) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result)));
                });
                if (result == "Connected") {
                  setState(() {
                    _isPrinterConnected = true;
                  });
                }
              }
            },
            icon: Icon(Icons.print),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            FilledButton(
              onPressed: _isPrinterConnected
                  ? () async {
                      if (_base64Image != null) {
                        log('Sending print command');
                        plugin.printImage(_base64Image!, width: pageWidth);
                        //plugin.printText("\n\n\n\n");
                        plugin.cutPaper();

                        log('Print command sent successfully');
                      } else {
                        log('No image to print');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No image to print')),
                        );
                      }
                    }
                  : null,
              child: Text("Print Test Page"),
            ),
            // Text('Bluetooth State: ${_bluetoothState.name}'),
            // ElevatedButton(
            //   onPressed: _checkBluetoothState,
            //   child: const Text('Check Bluetooth State'),
            // ),
          ],
        ),
      ),
    );
  }

  var myLongWidget = Builder(
    builder: (context) {
      return Container(
        width: double.infinity, // Use double.infinity for full width
        constraints: const BoxConstraints(
          maxHeight: 30000,
          //maxWidth: 565, // Constrain the widget height
        ),
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/logo.jpg", height: 200, fit: BoxFit.contain),
            
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 30.0,
                ),
                child: Column(
                  children: [
                    Text(
                      "Valanachery Road, Angadipuram",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    const Text(
                      "Mob:- +91 1234567890",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    const Text(
                      "GSTIN: 32AAAAA1234A1Z2",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Bill No: 123456",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Date: 01/01/2023",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Text(
                  "Time: 12:00 PM",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Customer Name: John Doe",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Text(
                  "Mobile: +91 9876543210",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 3, color: Colors.black, height: 5),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "Si",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: const Text(
                    "Item",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Qty",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: const Text(
                    "Price",
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(thickness: 3, color: Colors.black, height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "1",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: const Text(
                    "Samoosa",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "2",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: const Text(
                    "25.00",
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
           
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "12",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: const Text(
                    "Sample Biriyani item with a very long name",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "12",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: const Text(
                    "3425.00",
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "3",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: const Text(
                    "Chicken Condatum Biriyani with a very long name",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "12",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: const Text(
                    "125.00",
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "4",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: const Text(
                    "Beef Condatum Biriyani with a very long name",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "12",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: const Text(
                    "125.00",
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "5",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: const Text(
                    "Chicken curry",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "12",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: const Text(
                    "15.00",
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "6",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: const Text(
                    "Chicken Kuruma",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "12",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: const Text(
                    "1125.00",
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(thickness: 3, color: Colors.black, height: 5),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Taxable Amount: 325.00",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "GST Total: 325.00",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "CGST Total: 25.00",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "IGST Total: 125.00",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 3, color: Colors.black, height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Name :",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Text(
                  "Grand Total : 11234.00",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Mob:                 ",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(thickness: 3, color: Colors.black, height: 5),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Thank you for visiting!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    },
  );

  // Future<bool> _testPrint() async {
  //   try {
  //     final isConnected = await plugin.isConnected;
  //     if (!isConnected) {
  //       log('Printer is not connected');
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text('Printer is not connected')));
  //       });

  //       return false;
  //     }
  //     final imageBase64 = await _getImageAsBase64('assets/test_print.jpeg');
  //     plugin.printImage(imageBase64);

  //     plugin.printText("\n\n\n");

  //     log('Print command sent successfully');
  //     return true;
  //   } catch (e) {
  //     log('Error during print: $e');
  //     return false;
  //   }
  // }

  //  Future<String> _getImageAsBase64(String assetPath) async {
  //   try {
  //     // Load the image as bytes from the asset
  //     final ByteData data = await DefaultAssetBundle.of(
  //       context,
  //     ).load(assetPath);
  //     final List<int> bytes = data.buffer.asUint8List();

  //     // Convert bytes to Base64
  //     String base64Image = base64Encode(bytes);
  //     return base64Image;
  //   } catch (e) {
  //     log('Error loading asset image: $e');
  //     throw Exception('Error loading asset image: $e');
  //   }
  // }
}
