
class NotificationType {
  String name;
  String value;

  bool isSelected;

  NotificationType(
      {required this.name,
      required this.value,

      required this.isSelected});
}

class Model {
  Model({
    this.notification,
    this.data,
    this.to,
  });

  Model.fromJson(dynamic json) {
    notification = json['notification'] != null
        ? Notification.fromJson(json['notification'])
        : null;
    data = json['data'] != null ? ModelData.fromJson(json['data']) : null;
    to = json['to'];
  }
  Notification? notification;
  ModelData? data;
  String? to;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (notification != null) {
      map['notification'] = notification?.toJson();
    }
    if (data != null) {
      map['data'] = data?.toJson();
    }
    map['to'] = to;
    return map;
  }
}

class ModelData {
  ModelData({
    this.clickAction,
    this.title,
    this.body,
  });

  ModelData.fromJson(dynamic json) {
    clickAction = json['click_action'];
    title = json['title'];
    body = json['body'];
  }
  String? clickAction;
  String? title;
  String? body;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['click_action'] = clickAction;
    map['title'] = title;
    map['body'] = body;
    return map;
  }
}

class Notification {
  Notification({
    this.title,
    this.body,
    this.channelId,
  });

  Notification.fromJson(dynamic json) {
    title = json['title'];
    body = json['body'];
    channelId = json['android_channel_id'];
  }

  String? title;
  String? body;
  String? channelId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['body'] = body;
    map['android_channel_id'] = channelId;
    return map;
  }
}
