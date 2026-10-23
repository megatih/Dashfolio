import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import 'skin_scope.dart';

/// Skin-neutral icon identifiers. Screens name an icon; the active skin picks the glyph.
enum AppIcon {
  add(Icons.add, CupertinoIcons.add),
  addChart(Icons.add_chart, CupertinoIcons.chart_bar),
  addLink(Icons.add_link, CupertinoIcons.link),
  arrowBack(Icons.arrow_back, CupertinoIcons.chevron_back),
  backspace(Icons.backspace_outlined, CupertinoIcons.delete_left),
  block(Icons.block, CupertinoIcons.nosign),
  bookmark(Icons.bookmark_outline, CupertinoIcons.bookmark),
  bookmarkAdd(Icons.bookmark_add_outlined, CupertinoIcons.bookmark),
  brightnessAuto(Icons.brightness_auto, CupertinoIcons.circle_lefthalf_fill),
  cancel(Icons.cancel_outlined, CupertinoIcons.xmark_circle),
  candlestickChart(Icons.candlestick_chart_outlined, CupertinoIcons.graph_circle),
  candlestickChartFilled(Icons.candlestick_chart, CupertinoIcons.graph_circle_fill),
  check(Icons.check, CupertinoIcons.check_mark),
  checkCircle(Icons.check_circle_outline, CupertinoIcons.checkmark_circle),
  chevronRight(Icons.chevron_right, CupertinoIcons.chevron_right),
  circle(Icons.circle, CupertinoIcons.circle_fill),
  close(Icons.close, CupertinoIcons.xmark),
  cloudOff(Icons.cloud_off_outlined, CupertinoIcons.wifi_slash),
  contentCopy(Icons.content_copy, CupertinoIcons.doc_on_doc),
  currencyBitcoin(Icons.currency_bitcoin, CupertinoIcons.bitcoin),
  currencyExchange(Icons.currency_exchange, CupertinoIcons.arrow_right_arrow_left),
  danger(Icons.dangerous_outlined, CupertinoIcons.xmark_octagon),
  darkMode(Icons.dark_mode_outlined, CupertinoIcons.moon),
  dashboard(Icons.dashboard_outlined, CupertinoIcons.square_grid_2x2),
  dashboardFilled(Icons.dashboard, CupertinoIcons.square_grid_2x2_fill),
  delete(Icons.delete_outline, CupertinoIcons.delete),
  dragHandle(Icons.drag_indicator, CupertinoIcons.line_horizontal_3),
  download(Icons.download, CupertinoIcons.arrow_down_to_line),
  downloadDone(Icons.download_done, CupertinoIcons.checkmark_circle),
  edit(Icons.edit_outlined, CupertinoIcons.pencil),
  error(Icons.error_outline, CupertinoIcons.exclamationmark_circle),
  event(Icons.event, CupertinoIcons.calendar),
  expandMore(Icons.expand_more, CupertinoIcons.chevron_down),
  filterList(Icons.filter_list, CupertinoIcons.line_horizontal_3_decrease),
  fingerprint(Icons.fingerprint, CupertinoIcons.viewfinder),
  folder(Icons.folder_outlined, CupertinoIcons.folder),
  folderFilled(Icons.folder, CupertinoIcons.folder_fill),
  folderOpen(Icons.folder_open_outlined, CupertinoIcons.folder_open),
  helpOutline(Icons.help_outline, CupertinoIcons.question_circle),
  info(Icons.info_outline, CupertinoIcons.info),
  keyOff(Icons.key_off_outlined, CupertinoIcons.lock_slash),
  lightMode(Icons.light_mode_outlined, CupertinoIcons.sun_max),
  link(Icons.link, CupertinoIcons.link),
  linkOff(Icons.link_off, CupertinoIcons.link),
  lock(Icons.lock_outline, CupertinoIcons.lock),
  moreVertical(Icons.more_vert, CupertinoIcons.ellipsis_circle),
  openInNew(Icons.open_in_new, CupertinoIcons.arrow_up_right_square),
  password(Icons.password, CupertinoIcons.lock),
  pieChart(Icons.pie_chart_outline, CupertinoIcons.chart_pie),
  pieChartFilled(Icons.pie_chart, CupertinoIcons.chart_pie_fill),
  receipt(Icons.receipt_long_outlined, CupertinoIcons.doc_text),
  refresh(Icons.refresh, CupertinoIcons.arrow_clockwise),
  restore(Icons.restore, CupertinoIcons.arrow_counterclockwise),
  rule(Icons.rule, CupertinoIcons.list_bullet),
  savings(Icons.savings_outlined, CupertinoIcons.money_dollar_circle),
  savingsFilled(Icons.savings, CupertinoIcons.money_dollar_circle_fill),
  schedule(Icons.schedule, CupertinoIcons.clock),
  search(Icons.search, CupertinoIcons.search),
  searchOff(Icons.search_off, CupertinoIcons.search),
  settings(Icons.settings_outlined, CupertinoIcons.gear),
  settingsFilled(Icons.settings, CupertinoIcons.gear_solid),
  settingsEthernet(Icons.settings_ethernet, CupertinoIcons.antenna_radiowaves_left_right),
  shield(Icons.gpp_maybe_outlined, CupertinoIcons.shield),
  showChart(Icons.show_chart, CupertinoIcons.graph_square),
  star(Icons.star_border, CupertinoIcons.star),
  starFilled(Icons.star, CupertinoIcons.star_fill),
  swapHorizontal(Icons.swap_horiz, CupertinoIcons.arrow_right_arrow_left),
  sync(Icons.sync, CupertinoIcons.arrow_2_circlepath),
  tableChart(Icons.table_chart_outlined, CupertinoIcons.table),
  undo(Icons.undo, CupertinoIcons.arrow_uturn_left),
  uploadFile(Icons.upload_file, CupertinoIcons.arrow_up_doc),
  verifiedUser(Icons.verified_user_outlined, CupertinoIcons.checkmark_shield),
  visibility(Icons.visibility_outlined, CupertinoIcons.eye),
  vpnKey(Icons.vpn_key_outlined, CupertinoIcons.lock_shield),
  warning(Icons.warning_amber_rounded, CupertinoIcons.exclamationmark_triangle),
  warningOutlined(Icons.warning_amber_outlined, CupertinoIcons.exclamationmark_triangle);

  const AppIcon(this.material, this.cupertino);

  final IconData material;
  final IconData cupertino;

  IconData of(AppSkin skin) => skin == AppSkin.cupertino ? cupertino : material;
}

/// Renders an [AppIcon] with the glyph set of the active skin.
class AppIconView extends StatelessWidget {
  const AppIconView(this.icon, {super.key, this.size, this.color, this.semanticLabel});

  final AppIcon icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Icon(icon.of(AppSkinScope.of(context)), size: size, color: color, semanticLabel: semanticLabel);
}
