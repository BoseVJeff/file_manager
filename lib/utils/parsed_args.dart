import 'package:args/args.dart';
import 'package:logging/logging.dart';

class ParsedArgs {
  final String? fileDatabasePath;

  final bool showUi;

  static final ArgParser _argParser = ArgParser();

  static final Logger _logger = Logger("ParsedArgs");

  const ParsedArgs(this.fileDatabasePath, this.showUi);

  factory ParsedArgs.fromArgs(List<String> args) {
    _logger.fine("Parsing from args --> ${args.join(" ")}");
    _argParser.addFlag("show-ui", abbr: "i", negatable: true, defaultsTo: true);
    _argParser.addOption("database-path", abbr: "d", defaultsTo: null);

    ArgResults results = _argParser.parse(args);

    _logger.config("Recieved args --> $results");

    return ParsedArgs(results['database-path'], results['show-ui']);
  }

  @override
  int get hashCode => fileDatabasePath.hashCode + showUi.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is ParsedArgs) {
      return (showUi == other.showUi) &
          (fileDatabasePath == other.fileDatabasePath);
    } else {
      return false;
    }
  }
}
