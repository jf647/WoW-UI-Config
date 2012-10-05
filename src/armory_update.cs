using System;
using System.Text;
using System.IO;
using System.Collections.Generic;
using YamlDotNet.RepresentationModel;

class ArmoryUpdate
{

    public static void Main(string[] args)
    {

        string yamldoc = File.ReadAllText(args[0]);
        var yaml = new YamlStream();

        yaml.Load(new StringReader(yamldoc));

        var realms = ((YamlMappingNode)((YamlMappingNode)yaml.Documents[0].RootNode).Children[new YamlScalarNode("realms")]).Children;

        foreach( KeyValuePair<YamlNode, YamlNode> realmpair in realms ) {
            Console.WriteLine(String.Format("processing realm {0}", ((YamlScalarNode)realmpair.Key).Value));
            var chars = ((YamlMappingNode)((YamlMappingNode)realmpair.Value).Children[new YamlScalarNode("chars")]).Children;
            foreach( KeyValuePair<YamlNode, YamlNode> charpair in chars ) {
                Console.WriteLine(String.Format("  processing char {0}", ((YamlScalarNode)charpair.Key).Value));
            }
        }
        
    }

}
