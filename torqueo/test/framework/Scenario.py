#    Scenario.py: Scenario class in the torqueo framework.
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

import warnings

class Scenario:
      def __init__(self, description, urlDict):
          if(len(urlDict.keys()) == 0):
             raise Exception("Cannot set " + self.__class__.__name__ + ".urlDict to an empty dictionary.")
          else:
             self.description = description
             self.urlDict = urlDict
             self.tasks = []

      def addTask(self, task):
          if(hasattr(task, "setUrlDict")):
             task.setUrlDict(self.urlDict)
          else:
             raise Exception(task.__class__.__name__ + " does not implement setUrlDict()!")

          if(hasattr(task, "initializeTask")):
             task.initializeTask()
          else:
             raise Exception(task.__class__.__name__ + " does not implement initializeTask()!")

          if(hasattr(task, "run")):
             self.tasks.append(task)
          else:
             raise Exception(task.__class__.__name__ + " does not implement run()!")

      def setUrlDict(self, url):
          warnings.warn("Scenario.urlDict is a read-only property that can only be initialized in the constructor.")

      def getUrlDict(self):
          return self.urlDict

      def setUrl(self, key, value):
          warnings.warn("Cannot modify Scenario.urlDict because it is a read-only property")

      def getUrl(self, key):
          return self.urlDict[key]

      urlDict = property(getUrlDict, setUrlDict)

      def run(self):
          for task in self.tasks:
              if(hasattr(task, "run")):
                 task.run()
              else:
                 raise Exception(task.__class__.__name__ + " does not implement run()!")
