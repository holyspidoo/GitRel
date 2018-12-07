import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'dart:io';
import 'package:timeago/timeago.dart' as timeago;
import 'package:args/args.dart';

// Filename for saving dates
const String updateDatesFilename = 'updateDates.json';
// Add this to every github repo to get the feed url
const String releasesAtomString = '/releases.atom';
// Filename of textfile containing github repos
const String reposFileName = 'repos.txt';

// Storing dates when we run the app so we know about 
// new versions next time
var lastCheckedDates;
bool storeLastDates = false;
const String storeLastDatesString = 'storeLastDates';
// Map containing the update dates
Map<String, String> dateMap = Map<String, String>();

void main(List<String> arguments) async {
  final client = new http.Client();

  // If a username was provided in the arguments, parse that
  final parser = ArgParser();
  // -d flag means a file called updateDates.json is created
  // and will store dates so next time script runs, we know if
  // there's a new version. This file is stored in the RUN DIR!!
  parser.addFlag(storeLastDatesString,abbr: 'd');
  ArgResults argResults = parser.parse(arguments);
  List<String> argRest = argResults.rest;

  if (argResults[storeLastDatesString]){
    storeLastDates = true;

  }

  List<String> starFeedUrls = [];
  String githubUser;
  if (argRest.isNotEmpty) {
    // Get the starred repos from a user from the github api
    githubUser = argRest[0];
    String starUrl = "https://api.github.com/users/"+githubUser+"/starred";
    var starWeb = await client.get(starUrl);

    List jsonStar = jsonDecode(starWeb.body);

    // Convert starred urls to a list of atom feeds
    
    jsonStar.forEach((curMap) {
      String curUrl = curMap['html_url'];
      starFeedUrls.add(curUrl);
    });
  }

  client.close();

  List<String> lines = [];
  if (File(reposFileName).existsSync()) {
      // Text file containing all the repos
      lines = new File(reposFileName).readAsLinesSync();

  }


  // If we checked before, read the updateDates.json
  if(storeLastDates) {
      try {
        print("\nChecking to see if a previous update dates file exists here "+Directory.current.path+"/"+updateDatesFilename);
        if(File(updateDatesFilename).existsSync()){
          print("---> It does! Yay! <---");
          String jsonFile = File(updateDatesFilename).readAsStringSync();
          lastCheckedDates = json.decode(jsonFile);
        } else{
          print("it does not exist, it will be created this time.");
        }
        
      } catch (e) {
        // There is no update dates file yet
    
      }
  }

  if(starFeedUrls.isNotEmpty){
    print("\nProcessing Starred Repos from user "+githubUser);
    await processListOfFeeds(starFeedUrls);
  }
  
  if(lines.isNotEmpty){
    print("\nProcessing Repos from file "+reposFileName);
    await processListOfFeeds(lines);
  }
  
  if(lines.isEmpty && starFeedUrls.isEmpty){
    print("\nNo repos.txt file in current directory, nor was a gitHub user name");
    print("\nUSAGE:");
    print("GitRel [-d] [githubusername]\n");
    print("repos.txt should contain only one repo URL per line. Example:");
    print("https://github.com/acidanthera/WhateverGreen");
    print("https://github.com/acidanthera/Lilu");
  }

  // Write the new dateMap to disk if -d flag was used
  if(storeLastDates) {
    print("\nSaving update dates to file "+Directory.current.path+"/"+updateDatesFilename);
    String encodedJsonMap = json.encode(dateMap);
    File(updateDatesFilename).writeAsStringSync(encodedJsonMap);
  }

  print("\n");
  // Normal exit
  exit(0);
}

/// Takes a list of github repos URLs [lines] and looks at
/// their releases atom feeds. Will print the last version
/// and the last update date.
void processListOfFeeds(List<String> lines) async {
  
  // Map with String to print and Time of update
  Map<String,DateTime> mapToOrder = Map<String,DateTime>();

  var client = new http.Client();
  // For every repo, get the feed, and get the last version + updated date
  for (var line in lines) {
    String feedUrl = line + releasesAtomString;

    // Get the Feed
    var curFeed = await client.get(feedUrl);
    var feed = new AtomFeed.parse(curFeed.body);

    // Check if there are releases
    if (feed.items.isEmpty) {
      // Skip this one
      continue;
    }

    AtomItem item = feed.items.first;

    // Format the date for easy reading
    DateTime updatedTime = DateTime.parse(item.updated);
    String easyToReadTime = timeago.format(updatedTime);

    String stringBuilder = "-------------------------------------------------------\n";
    //print("-------------------------------------------------------");
    stringBuilder += feed.title.replaceFirst("Release notes from ", '')+", " + item.title.toString();
    //print(feed.title.replaceFirst("Release notes from ", '')+", " + item.title.toString());

    // If an old date exists, get that date and compare to the new date
    if (lastCheckedDates != null) {
      if (lastCheckedDates[feed.title] != null) {
        DateTime lastCheckedDateTime =
            DateTime.parse(lastCheckedDates[feed.title].toString());
        String easyToReadLastTime = timeago.format(lastCheckedDateTime);

        if (lastCheckedDateTime == updatedTime) {
          //print("Still the same version as last time you checked :(");
          stringBuilder += "\nStill the same version as last time you checked :(";
        } else {
          // NEW VERSION, mention it
          //print("----> NEW VERSION IS HERE <----");
          stringBuilder += "\n----> NEW VERSION IS HERE <----";
        }
      }
    }
    //print("Last update: \t" + easyToReadTime);
    stringBuilder += "\nLast update: \t" + easyToReadTime+"\n";

    //print(stringBuilder);

    // Add to Map
    dateMap[feed.title] = item.updated;

    // Add to sortMap
    mapToOrder[stringBuilder] = updatedTime;

  }

  // For every string, compare the updated time to sort the keys
  List mapKeys = mapToOrder.keys.toList(growable: false);
  mapKeys.sort(
    (k1,k2)=>mapToOrder[k1].compareTo(mapToOrder[k2])
    );
  
  // Just print the keys since those are the strings we want to print with all the info
  // including the date, no need to re-convert
  mapKeys.forEach(
    (k1){
    print(k1);
  });

  client.close();

}
