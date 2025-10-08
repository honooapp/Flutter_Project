class Exercise {
  String id;
  String exerciseTitle;
  String exerciseDescription;
  String exerciseImage;
  int parentId;
  String? exerciseDescriptionMore;
  String? exerciseIcon;
  String? exerciseIconName;

  Exercise(
    this.id,
    this.parentId,
    this.exerciseTitle,
    this.exerciseDescription,
    this.exerciseImage, {
    this.exerciseDescriptionMore,
    this.exerciseIcon,
    this.exerciseIconName,
  });
}
