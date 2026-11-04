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

part 'model/activity.dart';
part 'model/admin_health.dart';
part 'model/admin_jobs.dart';
part 'model/admin_overview.dart';
part 'model/admin_overview_jobs.dart';
part 'model/album.dart';
part 'model/album_create.dart';
part 'model/album_member.dart';
part 'model/album_rules.dart';
part 'model/album_update.dart';
part 'model/analysis_progress.dart';
part 'model/api_key.dart';
part 'model/api_key_create.dart';
part 'model/asset.dart';
part 'model/asset_detail.dart';
part 'model/asset_edits.dart';
part 'model/asset_ids.dart';
part 'model/asset_list.dart';
part 'model/asset_tag_change.dart';
part 'model/audit_entry.dart';
part 'model/auth_methods.dart';
part 'model/auth_status.dart';
part 'model/bulk_request.dart';
part 'model/bulk_response.dart';
part 'model/change_password_request.dart';
part 'model/checksum_check_request.dart';
part 'model/checksum_check_response.dart';
part 'model/comment.dart';
part 'model/comment_create.dart';
part 'model/create_device_key_request.dart';
part 'model/create_user_request.dart';
part 'model/crop_box.dart';
part 'model/device_key.dart';
part 'model/duplicate_group.dart';
part 'model/duplicate_item.dart';
part 'model/duplicates.dart';
part 'model/error.dart';
part 'model/external_library.dart';
part 'model/external_library_owner.dart';
part 'model/failed_job.dart';
part 'model/folder.dart';
part 'model/folder_entry.dart';
part 'model/health.dart';
part 'model/import_create.dart';
part 'model/import_entry.dart';
part 'model/job_queue.dart';
part 'model/link_password.dart';
part 'model/login_error.dart';
part 'model/login_request.dart';
part 'model/map_points.dart';
part 'model/map_style.dart';
part 'model/member_role.dart';
part 'model/memory.dart';
part 'model/oidc_exchange.dart';
part 'model/oidc_settings.dart';
part 'model/oidc_settings_update.dart';
part 'model/partner_entry.dart';
part 'model/partner_share.dart';
part 'model/partner_timeline.dart';
part 'model/partners.dart';
part 'model/passkey.dart';
part 'model/password_confirm.dart';
part 'model/people_list.dart';
part 'model/person.dart';
part 'model/person_ref.dart';
part 'model/person_update.dart';
part 'model/public_link.dart';
part 'model/quota_update.dart';
part 'model/search_filters.dart';
part 'model/search_result.dart';
part 'model/setup_request.dart';
part 'model/share_link.dart';
part 'model/share_link_create.dart';
part 'model/sprite.dart';
part 'model/story_export.dart';
part 'model/story_request.dart';
part 'model/tag.dart';
part 'model/timeline_bucket.dart';
part 'model/timeline_buckets.dart';
part 'model/timeline_buckets_buckets_inner.dart';
part 'model/timeline_item.dart';
part 'model/totp_code.dart';
part 'model/totp_setup.dart';
part 'model/trash_summary.dart';
part 'model/trip.dart';
part 'model/user.dart';
part 'model/user_ref.dart';
part 'model/user_storage.dart';
part 'model/vault_pin_change.dart';
part 'model/vault_session.dart';
part 'model/vault_status.dart';
part 'model/vault_unlock.dart';

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
