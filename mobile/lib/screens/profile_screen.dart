import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mediarr_api/api.dart';

import '../services/session.dart';
import '../theme.dart';

/// The letters shown for a person without a picture.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final only = parts.first;
    return only.substring(0, only.length < 2 ? 1 : 2).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Where a person's picture is, changing with each new one; null when there is none.
String? avatarUrl(Session session, User user) {
  final version = user.avatarVersion;
  if (version == null || version == 0) return null;
  return '${session.serverUrl}/api/users/${user.id}/avatar?v=$version';
}

/// A person: their picture when they have one, otherwise their initials on midnight blue.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.session,
    required this.user,
    this.size = 42,
  });

  final Session session;
  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl(session, user);
    final letters = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Palette.fill),
      child: Text(
        initialsOf(user.name),
        style: TextStyle(
          color: Palette.onFill,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.32,
        ),
      ),
    );
    if (url == null) return letters;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        httpHeaders: session.headers,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => letters,
        errorWidget: (_, _, _) => letters,
      ),
    );
  }
}

/// One's own name, email address and picture, as on the web.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final Session _start = ref.read(sessionProvider).value!;
  late final _name = TextEditingController(text: _start.user.name);
  late final _email = TextEditingController(text: _start.user.email);
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Session get _session => ref.read(sessionProvider).value!;

  bool get _emailChanged =>
      _email.text.trim().toLowerCase() != _session.user.email;

  void _tell(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final user = await _session.api.updateProfile(
        ProfileUpdate(
          name: _name.text.trim(),
          email: _emailChanged ? _email.text.trim() : null,
          currentPassword: _emailChanged ? _password.text : null,
        ),
      );
      if (user != null) ref.read(sessionProvider.notifier).updateUser(user);
      _password.clear();
      _tell('Saved.');
    } on ApiException catch (cause) {
      _tell(cause.message ?? 'The profile could not be saved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Sends the chosen picture as it is; the server cuts a square of it.
  Future<void> _choose() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final session = _session;
      final response = await http.put(
        Uri.parse('${session.serverUrl}/api/me/avatar'),
        headers: {
          ...session.headers,
          'Content-Type': picked.mimeType ?? 'image/jpeg',
        },
        body: await picked.readAsBytes(),
      );
      if (response.statusCode != 200) {
        final message =
            (jsonDecode(response.body) as Map<String, dynamic>?)?['message'];
        _tell('$message');
        return;
      }
      final user = User.fromJson(jsonDecode(response.body));
      if (user != null) ref.read(sessionProvider.notifier).updateUser(user);
    } on FormatException {
      _tell('The picture could not be sent.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    try {
      final user = await _session.api.removeAvatar();
      if (user != null) ref.read(sessionProvider.notifier).updateUser(user);
    } on ApiException catch (cause) {
      _tell(cause.message ?? 'The picture could not be removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value!;
    final hasPicture = avatarUrl(session, session.user) != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: PersonAvatar(
              session: session,
              user: session.user,
              size: 112,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : _choose,
                child: Text(hasPicture ? 'Change picture' : 'Add a picture'),
              ),
              if (hasPicture)
                TextButton(
                  onPressed: _busy ? null : _remove,
                  child: Text('Remove', style: TextStyle(color: Palette.err)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          if (_emailChanged) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(
                labelText: 'Current password, to change the email',
              ),
            ),
          ],
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
