#    Task.py: Base class for all Tasks
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

# Base class for all Tasks.

class Task:

      numberOfTasks = 0;

      def __init__(self):
          """Initialize properties of class"""
          self.urlDict = {}
          self.parameterizingMethods = {}
          Task.numberOfTasks += 1

      def setUrlDict(self, urlDict):
          """Setter for urlDict property"""
          self.urlDict = urlDict

      def getUrlDict(self, urlDict):
          """Getter for urlDict property"""
          return self.urlDict

      def setUrl(self, key, value):
          """Sets value to 'value' of particular url in URL dict identified by key 'key'"""
          self.urlDict[key] = value

      def getUrl(self, key):
          """Returns value of particular url in URL dict identified by key 'key'"""
          return self.urlDict[key]

      def callParameterizingMethodFor(self, key):
          """Calls parameterizing method associated with page identified by key 'key'"""
          if(self.parameterizingMethods.has_key(key)):
             self.parameterizingMethods[key]()

      def setParameterizingMethodFor(self, key, value):
          """Sets parameterizing method associated with page identified by key 'key' to method in 'value'"""
          self.parameterizingMethods[key] = value

      def getParameterizingMethodFor(self, key):
          """Returns the parameterizing method associated with page identified by key 'key'"""
          return self.parameterizingMethods[key]

      def instrumentMethod(self, test, method_name):
          """Instrument a method with the given Test."""
          unadorned = getattr(self.__class__, method_name)
          import new
          method = new.instancemethod(test.wrap(unadorned), None, self.__class__)
          setattr(self.__class__, method_name, method)
