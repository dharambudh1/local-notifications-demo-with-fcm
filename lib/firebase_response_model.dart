class FcmResponse {
  FcmResponse({
      this.multicastId, 
      this.success, 
      this.failure, 
      this.canonicalIds, 
      this.results,});

  FcmResponse.fromJson(dynamic json) {
    multicastId = json['multicast_id'];
    success = json['success'];
    failure = json['failure'];
    canonicalIds = json['canonical_ids'];
    if (json['results'] != null) {
      results = [];
      json['results'].forEach((v) {
        results?.add(Results.fromJson(v));
      });
    }
  }
  int? multicastId;
  int? success;
  int? failure;
  int? canonicalIds;
  List<Results>? results;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['multicast_id'] = multicastId;
    map['success'] = success;
    map['failure'] = failure;
    map['canonical_ids'] = canonicalIds;
    if (results != null) {
      map['results'] = results?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

class Results {
  Results({
      this.messageId, 
      this.error,});

  Results.fromJson(dynamic json) {
    messageId = json['message_id'];
    error = json['error'];
  }
  String? messageId;
  String? error;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['message_id'] = messageId;
    map['error'] = error;
    return map;
  }

}