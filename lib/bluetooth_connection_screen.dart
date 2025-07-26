import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:x_printer/x_printer.dart';
import 'package:xprinter2/main.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  StreamSubscription<BluetoothAdapterState>? _bluetoothAdapterListener;

  

  @override
  void initState() {
   _bluetoothAdapterListener=  FlutterBluePlus.adapterState.listen((state) {
      log('Bluetooth state changed: ${state.name}');
      if (state == BluetoothAdapterState.on) {
        log('Bluetooth is on');
        _startForPrinterScan();
      }
      setState(() {
        _bluetoothState = state;
      });
    });

    // _plugin.isScanningStream.listen((isScanning) {
    //   log('Is scanning: $isScanning');
    // });

    Future.delayed(Duration.zero, () async {
      final bluetoothState = await FlutterBluePlus.adapterState.first;

      if (bluetoothState == BluetoothAdapterState.off) {
        log('Bluetooth is off, attempting to turn it on...');
        _turnBluetoothOn();
      } else {
        log('Bluetooth is already on: ${bluetoothState.name}');
      }
    });

    super.initState();
  }

  Future<void> _turnBluetoothOn() async {
    // Request the user to turn on Bluetooth.
    // On Android, this will usually show a system dialog.
    // On iOS, it will typically direct the user to settings if off.
    await FlutterBluePlus.turnOn();
    // _checkBluetoothState(); // Recheck state after attempting to turn on
  }


  @override
  void dispose() {
    _bluetoothAdapterListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer Connection Screen')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          StreamBuilder(
            stream: plugin.isScanningStream,
            builder: (context, snapshot) {
              final isScanning = snapshot.data ?? false;
              if (isScanning) {
                return LinearProgressIndicator();
              }
              return SizedBox();
            },
          ),
          const SizedBox(height: 20),
          StreamBuilder(
            stream: plugin.peripheralsStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final peripherals = snapshot.data ?? [];
                return Expanded(
                  child: ListView.builder(
                    itemCount: peripherals.length,
                    itemBuilder: (context, index) {
                      final peripheral = peripherals[index];

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: ListTile(
                            leading: Icon(Icons.print),
                            title: Text(peripheral.name ?? "No Name"),
                            subtitle: Text(peripheral.uuid ?? "No UUID"),
                            trailing: FilledButton(
                              onPressed: () {
                                log('Connecting to ${peripheral.name}');
                                plugin
                                    .connect(peripheral.uuid!)
                                    .then((_) {
                                      WidgetsBinding.instance.addPostFrameCallback((
                                        _,
                                      ) {
                                        Navigator.of(context).pop("Connected");
                                      });
                                      // Close the connection screen after connecting
                                      // Close the connection screen
                                      log('Connected to ${peripheral.name}');
                                      // You can navigate to another screen or perform actions after connection
                                    })
                                    .catchError((error) {
                                      log(
                                        'Error connecting to ${peripheral.name}: $error',
                                      );
                                    });
                              },
                              child: Text('Connect'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Future _startForPrinterScan() async {
    plugin.startScan();
    await Future.delayed(const Duration(seconds: 5));
    plugin.stopScan();
  }

  
}
