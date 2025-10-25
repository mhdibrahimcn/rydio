class UberDriverTokens {
  UberDriverTokens({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
    required this.scope,
    this.refreshToken,
    DateTime? issuedAt,
  }) : issuedAt = (issuedAt ?? DateTime.now()).toUtc();

  final String accessToken;
  final int expiresIn;
  final String tokenType;
  final List<String> scope;
  final String? refreshToken;
  final DateTime issuedAt;

  factory UberDriverTokens.fromJson(Map<String, dynamic> json) {
    final scopesRaw = json['scope']?.toString() ?? '';
    final scopes =
        scopesRaw
            .split(RegExp(r'\s+'))
            .where((value) => value.isNotEmpty)
            .toList();

    return UberDriverTokens(
      accessToken: json['access_token']?.toString() ?? '',
      expiresIn: _tryParseInt(json['expires_in']) ?? 0,
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      scope: List.unmodifiable(scopes),
      refreshToken: json['refresh_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
      'scope': scope.join(' '),
      'refresh_token': refreshToken,
      'issued_at': issuedAt.toUtc().toIso8601String(),
    };
  }

  bool get isExpired {
    if (expiresIn <= 0) return true;
    final expiry = issuedAt.add(Duration(seconds: expiresIn - 60));
    return DateTime.now().toUtc().isAfter(expiry);
  }

  Duration get timeToExpiry {
    final expiry = issuedAt.add(Duration(seconds: expiresIn));
    return expiry.difference(DateTime.now().toUtc());
  }

  UberDriverTokens copyWith({
    String? accessToken,
    int? expiresIn,
    String? tokenType,
    List<String>? scope,
    String? refreshToken,
    DateTime? issuedAt,
  }) {
    return UberDriverTokens(
      accessToken: accessToken ?? this.accessToken,
      expiresIn: expiresIn ?? this.expiresIn,
      tokenType: tokenType ?? this.tokenType,
      scope: scope ?? this.scope,
      refreshToken: refreshToken ?? this.refreshToken,
      issuedAt: issuedAt ?? this.issuedAt,
    );
  }

  static int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
