import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'dart:io';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  var client = new http.Client();

  if(!File('repos.txt').existsSync()) {
    print("ERROR: You need a repos.txt file with the urls of github repos in it.\n");
    exit(-1);
  }

  // Text file containing all the repos
  List<String> lines = new File('repos.txt').readAsLinesSync();

  // If we checked before, read the updateDates.json
  var lastCheckedDates;

  try {
    String jsonFile = File('updateDates.json').readAsStringSync();
    lastCheckedDates = json.decode(jsonFile);
  } catch (e) {
    print(e);
  }

  // Map containing the update dates
  Map<String, String> dateMap = Map<String, String>();

  // For every repo, get the feed, and get the last version + updated date
  for (var line in lines) {
    String feedUrl = line + "/releases.atom";

    // Get the Feed
    var curFeed = await client.get(feedUrl);
    var feed = new AtomFeed.parse(curFeed.body);
    AtomItem item = feed.items.first;

    // Format the date for easy reading
    DateTime updatedTime = DateTime.parse(item.updated);
    String easyToReadTime = timeago.format(updatedTime);

    print("-------------------------------------------------------");
    print(feed.title);
    print("Latest Version: \t" + item.title.toString());

    // If an old date exists, get that date and compare to the new date
    if (lastCheckedDates != null) {
      if (lastCheckedDates[feed.title] != null) {
        DateTime lastCheckedDateTime =
            DateTime.parse(lastCheckedDates[feed.title].toString());
        String easyToReadLastTime = timeago.format(lastCheckedDateTime);

        if (lastCheckedDateTime == updatedTime) {
          print(
              "Still the same version as last time you checked :(");
        } else {
          // NEW VERSION, mention it
          print("----> NEW VERSION IS HERE <----");
        }
      }
    }
    print("Last update: \t" + easyToReadTime);

    print("\n");

    // Add to Map
    dateMap[feed.title] = item.updated;
  }

  // Write the new dateMap to disk
  String encodedJsonMap = json.encode(dateMap);
  File('updateDates.json').writeAsStringSync(encodedJsonMap);

  // Normal exit
  exit(0);
}
