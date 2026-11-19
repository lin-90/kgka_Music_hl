import '../models/music_models.dart';

/// 本地音乐扫描的文件夹分组工具。
///
/// 与 [FolderFilter] 对齐的纯函数：将歌曲按其父文件夹归组，
/// 支持路径规范化（统一分隔符、去尾部斜杠、转小写）与显示名提取，
/// 供 [LocalSongsPage] 的「按文件夹分组」视图使用。
class FolderGroup {
  const FolderGroup._();

  /// 规范化文件夹路径：统一分隔符、去尾部 `/`、转小写。
  ///
  /// 空字符串或空白输入返回 `null`。
  static String? normalizeFolderPath(String? path) {
    if (path == null) return null;
    var normalized = path.trim().replaceAll('\\', '/');
    while (normalized.endsWith('/') && normalized.length > 1) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.isEmpty || normalized == '/') return null;
    return normalized.toLowerCase();
  }

  /// 取文件所在父文件夹（已规范化）。无法解析时返回 `null`。
  static String? parentFolderOf(String? filePath) {
    if (filePath == null) return null;
    final normalized = filePath.trim().replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return null;
    return normalizeFolderPath(normalized.substring(0, index));
  }

  /// 取文件夹显示名：末级目录名；顶层存储目录（末级为 `0` 或 `storage`）显示完整路径。
  static String groupDisplayName(String folder) {
    final segs = folder.split('/').where((s) => s.isNotEmpty).toList();
    if (segs.isEmpty) return folder;
    final last = segs[segs.length - 1];
    if (last == '0' || last == 'storage') return folder;
    return last;
  }

  /// 按父文件夹分组歌曲。
  ///
  /// 返回的列表已排序：「其他」（无父目录）排最后，其余按显示名升序。
  static List<FolderGroupResult> groupByFolder(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final s in songs) {
      final parent = parentFolderOf(s.hash) ?? '';
      map.putIfAbsent(parent, () => []).add(s);
    }
    final arr = map.entries
        .map((entry) => FolderGroupResult(
              folder: entry.key,
              displayName: entry.key.isEmpty
                  ? '其他'
                  : groupDisplayName(entry.key),
              songs: entry.value,
            ))
        .toList();
    arr.sort((a, b) {
      if (a.folder.isEmpty) return 1;
      if (b.folder.isEmpty) return -1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return arr;
  }
}

/// 文件夹分组结果。
class FolderGroupResult {
  final String folder;
  final String displayName;
  final List<Song> songs;

  const FolderGroupResult({
    required this.folder,
    required this.displayName,
    required this.songs,
  });
}
