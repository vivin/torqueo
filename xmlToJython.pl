#    xmlToJython.pl: Converts XML data from TCPProxy to a Jython class
#    that implements the Task class in the torqueo framework.
#    Copyright (C) 2009 Vivin Suresh Paliath
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/perl

#
# XML to Jython converter. Written by Vivin S. Paliath on June 24th, 2009
#


 use strict;
 use XML::Simple;
 use Data::Dumper;

 my $version = "0.1";
 my $file = $ARGV[0];
 my $outputfile = $ARGV[1];
 my $filehandle;

 my $INIT_TAB = " " x 0;
 my $CLASS_TAB = " " x 6;
 my $DEF_TAB = " " x 4;
 my $IF_TAB = " " x 3;
 my $ELSE_TAB = " " x 3;

 my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
 my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
 my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
 my $year = 1900 + $yearOffset;
 my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";

 my %headers;

 # Used in the initializeTask method to make sure that all urls used in this task have been set
 my $urlDictCheckString = "if(";
 my $urlList = "[";

 my $xml = XML::Simple->new(KeyAttr=>[], ForceArray=>1); # Setting these attributes to maintain consistency and prevent folding
 my $data = $xml->XMLin($file);

 my $i = 0;

 if($outputfile eq "") {
    $filehandle = *STDOUT;
 }

 else {
    open(OUT, ">$outputfile");
    $filehandle = *OUT;
 }

 my $className = "RecordedTask";
 my $firstComment = $data->{"page"}->[0]->{"request"}->[0]->{"comment"}->[0];
 $firstComment =~ s/"/\\"/g;
 $firstComment =~ s/\s+/ /g;
 $firstComment =~ s/\n//g;

 my($pageMethodName, $commentString) = split(/\s*:\s*/, $firstComment);

 if($firstComment =~ /^@/) {
    $firstComment =~ s/ .*$//;
    $firstComment =~ s/@//;
    $className = $firstComment;
 }

 print $filehandle "# Converted from XML to Jython by xmlToJython.pl on $theTime\n";
 print $filehandle "# " . $data->{"metadata"}->[0]->{"version"}->[0] . "\n";
 print $filehandle "# HTTP script recorded by TCPProxy at " . $data->{"metadata"}->[0]->{"time"}->[0] . "\n\n";

 print $filehandle "from infusion.test.framework.Task import Task\n";
 print $filehandle "from HTTPClient import NVPair\n";
 print $filehandle "from net.grinder.plugin.http import HTTPPluginControl, HTTPRequest\n";
 print $filehandle "from net.grinder.script import Test\n";
 print $filehandle "from net.grinder.script.Grinder import grinder\n\n";

 if($className eq "RecordedTask") {
    print $filehandle "# You probably want to change the name of this task later\n";
    print $filehandle "# I suggest doing a global search and replace of \"RecordedTask\" with a name of your choosing\n";
}

 print $filehandle "class $className(Task):\n\n";

 print $filehandle "$INIT_TAB$CLASS_TAB" . "connectionDefaults = HTTPPluginControl.getConnectionDefaults()\n";
 print $filehandle "$INIT_TAB$CLASS_TAB" . "httpUtilities = HTTPPluginControl.getHTTPUtilities()\n\n";

 print $filehandle "$INIT_TAB$CLASS_TAB# To use a proxy server, uncomment the next line and set the host and port.\n";
 print $filehandle "$INIT_TAB$CLASS_TAB# connectionDefaults.setProxyServer(\"localhost\", 8001)\n\n";

 print $filehandle "$INIT_TAB$CLASS_TAB# These definitions at the top of the class are Class Variables (as opposed to\n";
 print $filehandle "$INIT_TAB$CLASS_TAB# Instance Variables) and are shared between all instances of this class.\n\n";

 foreach my $header(@{$data->{"common-headers"}}) {
    $headers{$header->{"headers-id"}} = $header->{"header"}   
 }

 $i = 0;
 my $numUris = scalar(@{$data->{"base-uri"}});
 foreach my $base_uri(@{$data->{"base-uri"}}) {
      if($i == 0) {
         $urlDictCheckString .= "not self.urlDict.has_key(\"" . $base_uri->{"uri-id"} . "\") ";
      }
      else {
         $urlDictCheckString .= "or not self.urlDict.has_key(\"" . $base_uri->{"uri-id"} . "\") ";
      }
      $urlList .= $base_uri->{"uri-id"} . ", ";
      $i++;
 }

 $urlDictCheckString =~ s/ $//;
 $urlDictCheckString .= "):";
 $urlList =~ s/, $//;
 $urlList .= "]";

 foreach my $headerId(sort{
                         if($a eq 'defaultHeaders') { return -1; }
                         elsif($b eq 'defaultHeaders') { return 1; }
                         else { my $tmp_a = $a; my $tmp_b = $b; $tmp_a =~ s/[^0-9]//g; $tmp_b =~ s/[^0-9]//g; return $tmp_a <=> $tmp_b; }
                      }(keys(%headers))){
    if($headerId eq "defaultHeaders") {
       print $filehandle "$INIT_TAB$CLASS_TAB" . "connectionDefaults.defaultHeaders = \\\n";
    }

    else {
       print $filehandle "$INIT_TAB$CLASS_TAB$headerId = \\\n";
    }

    print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB(\n";

    foreach my $headerAttributes(@{$headers{$headerId}}) {
       print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB  NVPair('" . $headerAttributes->{"name"} . "', '" . $headerAttributes->{"value"} . "'),\n" 
    }

    print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB)\n\n";
 }

 print $filehandle <<"JYTHON";
${INIT_TAB}${CLASS_TAB}def __init__(self):
${INIT_TAB}${CLASS_TAB}${DEF_TAB}"""Initialize properties of class"""
${INIT_TAB}${CLASS_TAB}${DEF_TAB}Task.__init__(self)
${INIT_TAB}${CLASS_TAB}${DEF_TAB}self.description = "$commentString"
${INIT_TAB}${CLASS_TAB}${DEF_TAB}self.urlDict = {}
${INIT_TAB}${CLASS_TAB}${DEF_TAB}self.taskId = Task.numberOfTasks

${INIT_TAB}${CLASS_TAB}def initializeTask(self):
${INIT_TAB}${CLASS_TAB}${DEF_TAB}"""Initializes Instance Variables for this class. This method will be called by the Scenario object that this task belongs to."""
${INIT_TAB}${CLASS_TAB}${DEF_TAB}$urlDictCheckString
${INIT_TAB}${CLASS_TAB}${DEF_TAB}${IF_TAB}raise Exception(self.__class__.__name__ + ".urlDict is missing values for one or more of the following keys: $urlList. Please define them in the constructor for the parent Scenario.")
${INIT_TAB}${CLASS_TAB}${DEF_TAB}else:
JYTHON

 my $pageNumber = 1;
 my $comment = "";
 my %parameters;
 my %methods;
 my %tokens;
 my $instrumentMethodsString = "";

 foreach my $page(@{$data->{'page'}}) {
    my $requestNumber = 1;
    my $requestRangeString = "";
    my $totalRequests = scalar @{$page->{'request'}};
    my $lastRequest = 1 + ($totalRequests - 1);
    my $methodBodyStr = "";
    my $description;
    my $firstSleepFound = 0; # First sleep for a page appears in the run() method. Subsequent sleeps appear within the method for the page itself

    $lastRequest = (length($lastRequest) == 1 ? "0$lastRequest" : $lastRequest);

    if($totalRequests == 1) {
       $requestRangeString = "(request ${pageNumber}01)";
    }

    else {
       $requestRangeString = "(requests ${pageNumber}01-$pageNumber$lastRequest)";
    }

    foreach my $request(@{$page->{'request'}}) {
       my $requestSuffix = "$pageNumber" . (length($requestNumber) == 1 ? "0$requestNumber" : $requestNumber);
       my $extendsUri = $request->{"uri"}->[0]->{"extends"};
       my $extendsHeader = $request->{"headers"}->[0]->{"extends"};
       
       $description = $request->{"description"}->[0];
       $description =~ s/\n//g;

       $comment = (length($request->{"comment"}->[0]) > 0) ? $request->{"comment"}->[0] : $comment;
       $comment =~ s/@[^ ]+ //;
       $comment =~ s/"/\\"/g;
       $comment =~ s/\s+/ /g;
       $comment =~ s/\n//g;

       my($pageMethodName, $commentString) = split(/\s*:\s*/, $comment);
       $pageMethodName = ($pageMethodName eq "") ? "page" : $pageMethodName;
       $commentString = ($commentString eq "") ? "Page $pageNumber" : "$commentString: ";
       $commentString =~ s/"/\\"/g;

       # If we have a token in the response, we need to store it in the %tokens hash 
       if($request->{"response"}->[0]->{"token-reference"}) {
          $tokens{$request->{"response"}->[0]->{"token-reference"}->[0]->{"token-id"}} = $request->{"response"}->[0]->{"token-reference"}->[0]->{"new-value"}->[0];
       }

       # If we have a body it means that we're POST'ing data; we need to grab those fields and values and put them into a hash
       if($request->{"body"}) {
          foreach my $NVPair(@{$request->{"body"}->[0]->{"form"}->[0]->{"form-field"}}) {
             $parameters{"$pageMethodName$pageNumber"}->{"$requestSuffix"}->{$NVPair->{"name"}} = $NVPair->{"value"};
          }
       }

       elsif($request->{"uri"}->[0]->{"query-string"}) { 
          # Looks like we've got a query string and we're using GET
          # Some nodes don't have a token-reference. They just have the a query string with no arguments. So we want 
          # to make sure that we do have arguments
          my $tokenReference = $request->{"uri"}->[0]->{"query-string"}->[0]->{"token-reference"};

          if($tokenReference) {
             foreach my $NVPair(@{$tokenReference}->[0]) {
                my $token_value = ($NVPair->{"new-value"} ? $NVPair->{"new-value"}->[0] : $tokens{$NVPair->{"token-id"}});
                $token_value =~ s/\s//g;

                my $token_id = $NVPair->{"token-id"};
                $token_id =~ s/token_//;
                $parameters{"$pageMethodName$pageNumber"}->{"$requestSuffix"}->{$token_id} = $token_value;
             }
          }
       }

       # Generating code to set request objects as Instance Variables
       print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB" . "self.request$requestSuffix = HTTPRequest(url=self.urlDict[\"$extendsUri\"], headers=$className.$extendsHeader)\n";
       print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB" . "self.request$requestSuffix = Test(int(str(self.taskId) + str($requestSuffix)), self.__class__.__name__ + \"(\" + str(self.taskId) + \") $commentString$description\").wrap(self.request$requestSuffix)\n\n";

       # While we're iterating through the pages and requests, we'll build our methods too. Here we're figuring out how to handle POSTs and GETs. POSTs expect a name-value pair
       # with NVPair, whereas with a GET you can simply construct a querystring

       if($request->{"method"}->[0] eq "POST") {
          my $path;

          # Some requests seem to have query strings along with POSTs, which really sucks in my opinion. I'm not sure why you would be sending stuff in a querystring if you are using POST
          # in the first place. Right now I'm just tacking it along to the path. Eventually it would be nice to have it parameterized.

          if($request->{"uri"}->[0]->{"query-string"}) {
             $path = $request->{"uri"}->[0]->{"unparsed"}->[0]
          }
 
          else {
             $path = $request->{"uri"}->[0]->{"path"}->[0]->{"text"}->[0];
          }

          $path =~ s/\s//g;

          $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB" . ($requestNumber == 1 ? "result = " : "") . "self.request$requestSuffix.POST('$path',\n";
          $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB$DEF_TAB(\n";

          foreach my $key(keys(%{$parameters{"$pageMethodName$pageNumber"}->{$requestSuffix}})) {
             $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB$DEF_TAB  NVPair('$key', self.parameters[\"$pageMethodName$pageNumber\"][\"$requestSuffix\"][\"$key\"]),\n"
          }

          $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB$DEF_TAB),\n";
          $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB$DEF_TAB( NVPair('" . $request->{"headers"}->[0]->{"header"}->[0]->{"name"} . "', '" . $request->{"headers"}->[0]->{"header"}->[0]->{"value"} . "'), )\n";
          $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB)\n";
       }

       elsif($request->{"method"}->[0] eq "GET") {
          my $path = $request->{"uri"}->[0]->{"path"}->[0]->{"text"}->[0];
          $path =~ s/\s//g;

          $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB" . ($requestNumber == 1 ? "result = " : "") . "self.request$requestSuffix.GET('$path'";

          # We only want to add a query string if we have parameters in this method
          if(exists $parameters{"$pageMethodName$pageNumber"}) {
             # We also want to make sure that the current request has parameters. You might wonder why we don't do if(exists $parameters{"$pageMethodName$pageNumber"}->{$requestSuffix}
             # This is because perl autovivifies (creates if something doesn't exist) any intervening references. So we'll end up with references to empty hashes, which we don't want
             if(exists $parameters{"$pageMethodName$pageNumber"}->{$requestSuffix}) {
                $methodBodyStr .= "+\n";
                my $i = 0;
                foreach my $key(keys(%{$parameters{"$pageMethodName$pageNumber"}->{$requestSuffix}})) {
                   my $queryStringStart = ($i == 0 ? "?" : "");
                   $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB$DEF_TAB'$queryStringStart$key=' + self.parameters[\"$pageMethodName$pageNumber\"][\"$requestSuffix\"][\"$key\"] + '&'\n";
                }
                $methodBodyStr =~ s/ \+ '&'$//;
                $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB)\n";
             }

             else {
                # This method has parameters defined, but for another request
                $methodBodyStr .= ")\n";
             }
          }

          elsif(exists $request->{"uri"}->[0]->{"query-string"}->[0]->{"text"}) {
             # This means we have a strange query string, in which case we're just going to add the unparsed value
             $methodBodyStr .= " + '?" . $request->{"uri"}->[0]->{"query-string"}->[0]->{"text"}->[0] . "')\n";
          }

          else {
             $methodBodyStr .= ")\n";
          }
       }
 
       if($request->{"response"}->[0]->{"status-code"} ne "200") {
          $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB# Expecting " . $request->{"response"}->[0]->{"status-code"} . "'" . $request->{"response"}->[0]->{"reason-phrase"} . "'\n";
          if($request->{"response"}->[0]->{"token-reference"}) {
             my $token_id = $request->{"response"}->[0]->{"token-reference"}->[0]->{"token-id"};
             my $id = $token_id;
             $id =~ s/token_//;

             my $token_value = $request->{"response"}->[0]->{"token-reference"}->[0]->{"new-value"}->[0];
             $token_value =~ s/\s//g;
             $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB" . "self.$token_id = $className.httpUtilities.valueFromLocationURI('$id') # $token_value\n\n";
          }
       }

       else {
          $methodBodyStr .= "\n";
       }
 
       if($firstSleepFound and $request->{"sleep-time"}) {
          $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB" . "grinder.sleep(" . $request->{"sleep-time"}->[0] . ")\n\n";
       }

       else {
          $methods{"$pageMethodName$pageNumber"}->{"first-sleep"} = $request->{"sleep-time"}->[0];
          $firstSleepFound = 1;
       }
       $requestNumber++;
    }

    $methodBodyStr .= "$INIT_TAB$CLASS_TAB$DEF_TAB" . "return result";

    my($pageMethodName, $commentString) = split(/\s*:\s*/, $comment);

    $instrumentMethodsString .= "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB" . "self.instrumentMethod(Test(int(str(self.taskId) + str(${pageNumber}00)), self.__class__.__name__ + \"(\" + str(self.taskId) + \") $commentString\"), '$pageMethodName$pageNumber')\n";

    $methods{"$pageMethodName$pageNumber"}->{"signature"} = "$INIT_TAB$CLASS_TAB" . "def $pageMethodName$pageNumber(self):";
    $methods{"$pageMethodName$pageNumber"}->{"commenstring"} = "$INIT_TAB$CLASS_TAB$DEF_TAB# $commentString $description $requestRangeString.";
    $commentString =~ s/"/\\"/g;
    $methods{"$pageMethodName$pageNumber"}->{"docstring"} = "$INIT_TAB$CLASS_TAB$DEF_TAB\"\"\"$commentString $description $requestRangeString.\"\"\"";
    $methods{"$pageMethodName$pageNumber"}->{"body"} = $methodBodyStr;

    $pageNumber++;
 }

 print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB" . "self.parameters = \\\n";
 print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB" . "{\n";
 
 $i = 0;
 my $numPages = scalar(keys(%parameters));

 foreach my $page(sort{
                     my $tmp_a = $a; my $tmp_b = $b; $tmp_a =~ s/[^0-9]//g; $tmp_b =~ s/[^0-9]//g; return $tmp_a <=> $tmp_b;
                  }(keys(%parameters))){

   print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB$DEF_TAB\"$page\":\n";
   print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB$DEF_TAB" . "{\n";

   my $numRequests = scalar(keys(%{$parameters{$page}}));
   my $j = 0;

   foreach my $request(sort{$a <=> $b}(keys(%{$parameters{$page}}))) {
      print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB$DEF_TAB$DEF_TAB\"$request\":\n";
      print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB$DEF_TAB$DEF_TAB" . "{\n";

      my $numNVPairs = scalar(keys(%{$parameters{$page}->{$request}}));
      my $k = 0;

      foreach my $key(keys(%{$parameters{$page}->{$request}})) {
         print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB$DEF_TAB$DEF_TAB$DEF_TAB\"$key\":\"" . $parameters{$page}->{$request}->{$key} . "\"" . (($k == $numNVPairs - 1) ? "\n" : ",\n");
         $k++;
      }

      print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB$DEF_TAB$DEF_TAB}" . (($j == $numRequests - 1) ? "\n" : ",\n");
      $j++;
   }
   
   print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB$DEF_TAB}" . (($i == $numPages - 1) ? "\n" : ",\n");
   $i++;
 }

 print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB$ELSE_TAB}\n\n";

 print $filehandle "$instrumentMethodsString\n";

 foreach my $methodName(sort{
                           my $tmp_a = $a; my $tmp_b = $b; $tmp_a =~ s/[^0-9]//g; $tmp_b =~ s/[^0-9]//g; return $tmp_a <=> $tmp_b;
                        }(keys(%methods))){
    print $filehandle $methods{$methodName}->{"signature"} . "\n";
    print $filehandle $methods{$methodName}->{"docstring"} . "\n";
    print $filehandle $methods{$methodName}->{"body"} . "\n\n";
 }

 print $filehandle "$INIT_TAB$CLASS_TAB" . "def run(self):\n";
 print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB\"\"\"The run() method runs all the tests in this Task\"\"\"\n";

 foreach my $methodName(sort{
                           my $tmp_a = $a; my $tmp_b = $b; $tmp_a =~ s/[^0-9]//g; $tmp_b =~ s/[^0-9]//g; return $tmp_a <=> $tmp_b;
                        }(keys(%methods))){
    print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB" . "self.callParameterizingMethodFor('$methodName')\n";
    print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB" . "self.$methodName()   " . $methods{$methodName}->{"commentstring"} . "\n";

    if($methods{$methodName}->{"first-sleep"}) {
       print $filehandle "$INIT_TAB$CLASS_TAB$DEF_TAB" . "grinder.sleep(" . $methods{$methodName}->{"first-sleep"} . ")\n";
    }

    print $filehandle "\n";
 }

# my $d = Data::Dumper->new([\%methods], ["methods"]);
# $d->Sortkeys(1);
# print $d->Dump;
