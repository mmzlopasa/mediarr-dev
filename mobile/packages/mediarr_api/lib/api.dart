//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/default_api.dart';

part 'model/admin_overview.dart';
part 'model/admin_overview_jobs.dart';
part 'model/asset.dart';
part 'model/asset_detail.dart';
part 'model/asset_list.dart';
part 'model/auth_status.dart';
part 'model/bulk_request.dart';
part 'model/bulk_response.dart';
part 'model/change_password_request.dart';
part 'model/checksum_check_request.dart';
part 'model/checksum_check_response.dart';
part 'model/create_device_key_request.dart';
part 'model/create_user_request.dart';
part 'model/device_key.dart';
part 'model/error.dart';
part 'model/health.dart';
part 'model/login_error.dart';
part 'model/login_request.dart';
part 'model/password_confirm.dart';
part 'model/setup_request.dart';
part 'model/sprite.dart';
part 'model/timeline_bucket.dart';
part 'model/timeline_buckets.dart';
part 'model/timeline_buckets_buckets_inner.dart';
part 'model/timeline_item.dart';
part 'model/totp_code.dart';
part 'model/totp_setup.dart';
part 'model/user.dart';

/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) =>
    pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
