public inherited sharing class ReportFolderHirearchy {
  private static ReportFolderHirearchy currentInstance = null;

  public Map<Id, List<Folder>> parentFolderMap { get; private set; }
  public Map<String, Id> folderNameIdMap { get; private set; }

  private ReportFolderHirearchy() {
    this.parentFolderMap = getParentChildFolderMap();
    this.folderNameIdMap = getFolderNameIdMap();
  }

  public static ReportFolderHirearchy getInstance() {
    if (currentInstance == null) {
      currentInstance = new ReportFolderHirearchy();
    }
    return currentInstance;
  }

  public Map<Id, Id> relatedFoldersRelocationMap(String topLevelFolderName, String relocateFolderName) {
    Id topLevelFolderId = folderNameIdMap.get(topLevelFolderName);
    Id relocateFolderId = folderNameIdMap.get(relocateFolderName);
    Map<Id, Id> folderRelocationIdMap = new Map<Id, Id>();
    Set<Id> folderIds = new Set<Id>();

    if (topLevelFolderId == null || relocateFolderId == null) {
      return folderRelocationIdMap;
    }

    folderIds = traverseFolderHirearchy(folderIds, parentFolderMap.get(topLevelFolderId));
    folderRelocationIdMap.put(topLevelFolderId, relocateFolderId);

    for (Id i : folderIds) {
      folderRelocationIdMap.put(i, relocateFolderId);
    }

    return folderRelocationIdMap;
  }

  private Set<Id> traverseFolderHirearchy(Set<Id> folderIds, List<Folder> folders) {
    List<Folder> children = new List<Folder>();

    for (Folder f : folders) {
      folderIds.add(f.Id);
      if (parentFolderMap.containskey(f.Id)) {
        children.addAll(parentFolderMap.get(f.Id));
      }
    }

    if (!children.isEmpty()) {
      traverseFolderHirearchy(folderIds, children);
    }
    return folderIds;
  }

  private Map<Id, List<Folder>> getParentChildFolderMap() {
    Map<Id, List<Folder>> parentFolderMap = new Map<Id, List<Folder>>();

    for (Folder f : getAllFolders()) {
      if (f.parentId == null) {
        if (!parentFolderMap.containsKey(f.Id)) {
          parentFolderMap.put(f.Id, new List<Folder>());
        }
        continue;
      }

      if (!parentFolderMap.containsKey(f.parentId)) {
        parentFolderMap.put(f.parentId, new List<Folder>());
      }
      parentFolderMap.get(f.parentId).add(f);
    }
    return parentFolderMap;
  }

  private Map<String, Id> getFolderNameIdMap() {
    Map<String, Id> folders = new Map<String, Id>();

    for (Folder f : getAllFolders()) {
      folders.put(f.DeveloperName, f.Id);
    }
    return folders;
  }

  private List<Folder> getAllFolders() {
    return [SELECT Id, Name, DeveloperName, ParentId FROM Folder WHERE Type = 'Report'];
  }
}
