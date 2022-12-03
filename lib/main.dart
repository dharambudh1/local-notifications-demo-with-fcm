import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:push_notifications_demo/firebase_response_model.dart';
import 'package:push_notifications_demo/firebase_request_model.dart' as model;

import 'firebase_request_model.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final String currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(currentTimeZone));

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling a background message ${message.messageId}');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Firebase Cloud Messaging Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

const String overlayNotification = 'overlay_notification_channel';
const String instantNotification = 'instant_notification_channel';
const String instantNotificationWithCustomSound =
    'instant_notification_channel_with_custom_sound';
const String scheduledNotification = 'scheduled_notification_channel';

const AndroidNotificationChannel overlayNotificationChannel =
    AndroidNotificationChannel(
  overlayNotification, // id
  'Overlay Notifications', // title
  description: 'This channel is used for overlay notifications.', // description
  showBadge: true,
  importance: Importance.high,
  playSound: true,
);

const AndroidNotificationChannel instantNotificationChannel =
    AndroidNotificationChannel(
  instantNotification, // id
  'Instant Notifications', // title
  description: 'This channel is used for instant notifications.', // description
  showBadge: true,
  importance: Importance.high,
  playSound: true,
);

const AndroidNotificationChannel instantNotificationChannelWithCustomSound =
    AndroidNotificationChannel(
  instantNotificationWithCustomSound, // id
  'Instant Notifications with custom sound', // title
  description:
      'This channel is used for instant notifications with custom sound.', // description
  importance: Importance.high,
  playSound: true,
  showBadge: true,
  enableLights: true,
  enableVibration: true,
  sound: RawResourceAndroidNotificationSound('slow_spring_board'),
);

const AndroidNotificationChannel scheduledNotificationChannel =
    AndroidNotificationChannel(
  scheduledNotification, // id
  'Scheduled Notifications', // title
  description:
      'This channel is used for schedule notifications.', // description
  importance: Importance.high,
  playSound: true,
  showBadge: true,
  enableLights: true,
  enableVibration: true,
  sound: RawResourceAndroidNotificationSound('slow_spring_board'),
);

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late final FirebaseMessaging _firebaseMessaging;

  model.Model? _notificationModel;
  FcmResponse? _fcmResponse;

  final TextEditingController _controllerTitle = TextEditingController();
  final TextEditingController _controllerBody = TextEditingController();
  final TextEditingController _controllerDataTitle = TextEditingController();
  final TextEditingController _controllerDataBody = TextEditingController();

  String fcmToken = '';
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<NotificationType> _list = [];

  listInit() {
    _list = [
      model.NotificationType(
        name: 'Overlay',
        value: overlayNotification,
        isSelected: true,
      ),
      model.NotificationType(
        name: 'Instant',
        value: instantNotification,
        isSelected: false,
      ),
      model.NotificationType(
        name: 'Instant with custom sound',
        value: instantNotificationWithCustomSound,
        isSelected: false,
      ),
      model.NotificationType(
        name: 'Scheduled for 10 sec',
        value: scheduledNotification,
        isSelected: false,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listInit();

    _firebaseMessaging = FirebaseMessaging.instance;

    //init firebase
    initToken();

    //foreground
    registerNotification();

    //background
    backgroundNotification();

    //app terminated
    checkForInitialMessage();
  }

  Future<void> initToken() async {
    fcmToken = await _firebaseMessaging.getToken() ?? '';
    setState(() {});
    return Future.value();
  }

  void registerNotification() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(overlayNotificationChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(instantNotificationChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(instantNotificationChannelWithCustomSound);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(scheduledNotificationChannel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        log('AuthorizationStatus.authorized');
        break;
      case AuthorizationStatus.denied:
        log('AuthorizationStatus.denied');
        break;
      case AuthorizationStatus.notDetermined:
        log('AuthorizationStatus.notDetermined');
        break;
      case AuthorizationStatus.provisional:
        log('AuthorizationStatus.provisional');
        break;
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //foreground handler
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage event) {
          log('-----------------------------------------');
          log('FirebaseMessaging.onMessage.listen called');
          log('-----------------------------------------');

          modelBinding(event);
          if (_notificationModel != null) {
            showNotification(event);
          }
        },
      );
    }
  }

  showNotification(RemoteMessage event) {
    RemoteNotification? notification = event.notification;
    AndroidNotification? android = event.notification?.android;
    AppleNotification? ios = event.notification?.apple;
    if (notification != null && (android != null || ios != null)) {
      return notification.android?.channelId == overlayNotification
          ? customShowOverlayNotification()
          : notification.android?.channelId == instantNotification
              ? instantNotificationView(notification, event)
              : notification.android?.channelId ==
                      instantNotificationWithCustomSound
                  ? instantNotificationWithCustomSoundView(notification, event)
                  : notification.android?.channelId == scheduledNotification
                      ? zonedScheduleNotificationView(notification, event)
                      : null;
    }
  }

  void backgroundNotification() {
    FirebaseMessaging.onMessageOpenedApp.listen(modelBinding);
  }

  void checkForInitialMessage() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    RemoteMessage? event = await FirebaseMessaging.instance.getInitialMessage();

    if (event != null) {
      modelBinding(event);
    }
  }

  void modelBinding(RemoteMessage event) {
    log('-----------------------------------------');
    log('modelBinding called');
    log('-----------------------------------------');

    model.Model object = model.Model(
      to: fcmToken,
      notification: model.Notification(
          channelId: event.notification?.android?.channelId ?? '',
          title: event.notification?.title ?? '',
          body: event.notification?.body ?? ''),
      data: model.ModelData(
          title: event.data['title'] ?? '',
          body: event.data['body'] ?? '',
          clickAction: event.data['click_action'] ?? ''),
    );

    setState(() {
      _notificationModel = object;
    });
  }

  OverlaySupportEntry customShowOverlayNotification() {
    return showSimpleNotification(
      leading: const Icon(Icons.circle_notifications),
      Text(_notificationModel?.notification?.title ?? ''),
      subtitle: Text(_notificationModel?.notification?.body ?? ''),
    );
  }

  Future instantNotificationView(
      RemoteNotification notification, RemoteMessage event) {
    return flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          instantNotificationChannel.id,
          instantNotificationChannel.name,
          channelDescription: instantNotificationChannel.description,
          // color: Colors.red,
          color: Color(int.parse(notification.android?.color ?? "0xFF0D47A1")),
          playSound: true,
          // icon: android?.smallIcon,
          icon: '@drawable/ic_launcher',
          // sound: const RawResourceAndroidNotificationSound(
          //     'slow_spring_board'),
          importance: Importance.high,
          priority: Priority.high,
          largeIcon:
              const DrawableResourceAndroidBitmap('@drawable/ic_launcher'),
        ),
        iOS: IOSNotificationDetails(
          threadIdentifier: instantNotificationChannel.id,
          subtitle: instantNotificationChannel.description,
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          // sound: 'slow_spring_board.aiff',
        ),
      ),
      payload: event.data.toString(),
    );
  }

  Future instantNotificationWithCustomSoundView(
      RemoteNotification notification, RemoteMessage event) {
    return flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          instantNotificationChannelWithCustomSound.id,
          instantNotificationChannelWithCustomSound.name,
          channelDescription:
              instantNotificationChannelWithCustomSound.description,
          // color: Colors.red,
          color: Color(int.parse(notification.android?.color ?? "0xFF0D47A1")),
          playSound: true,
          // icon: android?.smallIcon,
          icon: '@drawable/ic_launcher',
          sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
          importance: Importance.high,
          priority: Priority.high,
          largeIcon:
              const DrawableResourceAndroidBitmap('@drawable/ic_launcher'),
        ),
        iOS: IOSNotificationDetails(
          threadIdentifier: instantNotificationChannelWithCustomSound.id,
          subtitle: instantNotificationChannelWithCustomSound.description,
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          sound: 'slow_spring_board.aiff',
        ),
      ),
      payload: event.data.toString(),
    );
  }

  Future zonedScheduleNotificationView(
      RemoteNotification notification, RemoteMessage event) {
    return flutterLocalNotificationsPlugin.zonedSchedule(
      notification.hashCode,
      notification.title,
      notification.body,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      NotificationDetails(
        android: AndroidNotificationDetails(
          scheduledNotificationChannel.id,
          scheduledNotificationChannel.name,
          channelDescription:
          scheduledNotificationChannel.description,
          // color: Colors.red,
          color: Color(int.parse(notification.android?.color ?? "0xFF0D47A1")),
          playSound: true,
          // icon: android?.smallIcon,
          icon: '@drawable/ic_launcher',
          sound: const RawResourceAndroidNotificationSound('slow_spring_board'),
          importance: Importance.high,
          priority: Priority.high,
          largeIcon:
              const DrawableResourceAndroidBitmap('@drawable/ic_launcher'),
        ),
        iOS: IOSNotificationDetails(
          threadIdentifier: scheduledNotificationChannel.id,
          subtitle: scheduledNotificationChannel.description,
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
          sound: 'slow_spring_board.aiff',
        ),
      ),
      payload: event.data.toString(),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.inactive:
        onPaused();
        break;
      case AppLifecycleState.paused:
        onInactive();
        break;
      case AppLifecycleState.detached:
        onDetached();
        break;
    }
  }

  void onResumed() {
    log('onResumed');
  }

  void onPaused() {
    log('onPaused');
  }

  void onInactive() {
    log('onInactive');
  }

  void onDetached() {
    log('onDetached');
  }

  @override
  void dispose() {
    _controllerTitle.dispose();
    _controllerBody.dispose();
    _controllerDataTitle.dispose();
    _controllerDataBody.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push notification demo'),
      ),
      body: GestureDetector(
        onTap: FocusManager.instance.primaryFocus?.unfocus,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  const Text(
                      "Note: I configured this project with Firebase command-line interface. But due to the lack of an iOS physical phone, I haven't tested this project on any iOS device. This firebase cloud messaging demo works only with Android emulators, Android devices and Apple real iPhones (excluding iPhone simulators)."),
                  const SizedBox(
                    height: 30,
                  ),
                  _notificationModel == null
                      ? const Text('Notification model is empty!')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Notification:'),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                                'title: ${_notificationModel?.notification?.title ?? ''}'),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                                'body: ${_notificationModel?.notification?.body ?? ''}'),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                                'dataTitle: ${_notificationModel?.data?.title ?? ''}'),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                                'dataBody: ${_notificationModel?.data?.body ?? ''}'),
                          ],
                        ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        TextFormField(
                          controller: _controllerTitle,
                          decoration:
                              const InputDecoration(label: Text('Title')),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some Title';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _controllerBody,
                          decoration:
                              const InputDecoration(label: Text('Body')),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some Body';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _controllerDataTitle,
                          decoration:
                              const InputDecoration(label: Text('Data title')),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some Data Title';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _controllerDataBody,
                          decoration:
                              const InputDecoration(label: Text('Data Body')),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some Data Body';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              shrinkWrap: true,
                              itemCount: _list.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  splashColor: Colors.pinkAccent,
                                  onTap: () {
                                    setState(() {
                                      _list.forEach((gender) {
                                        gender.isSelected = false;
                                      });
                                      _list[index].isSelected = true;
                                    });
                                  },
                                  child: CustomRadio(_list[index]),
                                );
                              }),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              FocusManager.instance.primaryFocus?.unfocus();

                              var op = _list.firstWhere(
                                  (element) => element.isSelected == true);

                              model.Model object = model.Model(
                                notification: model.Notification(
                                  channelId: op.value,
                                  title: _controllerTitle.value.text.trim(),
                                  body: _controllerBody.value.text.trim(),
                                ),
                                data: model.ModelData(
                                    title:
                                        _controllerDataTitle.value.text.trim(),
                                    body: _controllerDataBody.value.text.trim(),
                                    clickAction: "FLUTTER_NOTIFICATION_CLICK"),
                                to: fcmToken,
                              );

                              callAPI(object);
                            }
                          },
                          child: const Text('Submit'),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                  _fcmResponse == null
                      ? const Text('Response model is empty!')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Response:'),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                                'multicastId: ${_fcmResponse?.multicastId ?? ''}'),
                            const SizedBox(
                              height: 4,
                            ),
                            Text('success: ${_fcmResponse?.success ?? ''}'),
                            const SizedBox(
                              height: 4,
                            ),
                            Text('failure: ${_fcmResponse?.failure ?? ''}'),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                                'canonicalIds: ${_fcmResponse?.canonicalIds ?? ''}'),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                                'messageId: ${_fcmResponse?.results?.first.messageId ?? ''}'),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                                'error: ${_fcmResponse?.results?.first.error ?? ''}'),
                          ],
                        )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<FcmResponse> callAPI(model.Model object) async {
    Dio dio = Dio();
    log("REQUEST: ${json.encode(object)}");
    Response<dynamic> response = await dio.post(
      'https://fcm.googleapis.com/fcm/send',
      data: json.encode(object),
      options: Options(
        validateStatus: (_) => true,
        contentType: Headers.jsonContentType,
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "key=AAAAuaWsA0w:APA91bF0sH3iwO33aTSbAmfcS50byeY1e04aCkDQkQPa6bYtdwQbGfva3t7A9ziaoXmArctJSeFGfstcSHtXYrAerB2KHhMusMP9zrQEURFu1KYz1Jv9WmaS2109e-1oP_fneFoxGGFJ"
        },
        responseType: ResponseType.json,
      ),
    );

    if (response.statusCode == 200) {
      _fcmResponse = FcmResponse.fromJson(response.data);
      setState(() {});
    } else {
      _fcmResponse = FcmResponse();
    }

    return _fcmResponse ?? FcmResponse();
  }
}

class CustomRadio extends StatelessWidget {
  final NotificationType _gender;

  const CustomRadio(this._gender, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _gender.isSelected ? const Color(0xFF3B4257) : Colors.white,
      child: Container(
        height: 80,
        width: 80,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(5.0),
        child: Text(
          _gender.name,
          style:
              TextStyle(color: _gender.isSelected ? Colors.white : Colors.grey),
        ),
      ),
    );
  }
}
