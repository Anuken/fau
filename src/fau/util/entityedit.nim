import polymorph, ../../core, ../g2/imgui, varedit
import sequtils, strutils

onEcsBuilt:
  var 
    entityEditorShown: bool
    searchText: string = ""

  import sequtils, strutils, varedit, tables

  proc showEntityEditor*(toggleKey = keyF2) =
    if toggleKey.tapped:
      entityEditorShown = not entityEditorShown

    if entityEditorShown:
    
      igBegin("Entities", addr entityEditorShown)
      
      igInputTextWithHint("##Search", "Search", searchText)

      if entityCount() != 0:
        var total = 0
        for i in 0 ..< entityStorage.nextEntityId.int:
          if total > 100:
            break
          
          let ent = (i.EntityId).makeRef

          if not ent.alive: continue

          let systemStr = ent.listSystems()

          if (searchText == "" or systemStr.toLowerAscii.contains(searchText.toLowerAscii)):
            total.inc
            
            if igCollapsingHeader(cstring($ent.entityId.int & " [" & (systemStr.split('\n').mapIt(it.split(' ')[0])).join(" ")[0..^2] & "]")):
            
              igPushID(ent.entityId.int32)
              igPushItemWidth(300f)

              if ent.componentCount > 0:
                for compRef in ent.components:
                  caseComponent(compRef.typeId):
                    #TODO: delete button

                    igSeparator()

                    var data = componentInstanceType()(compRef.index.int).access

                    var fieldCount = 0
                    for _, _ in data.fieldpairs:
                      fieldCount.inc
                    
                    let disabled = fieldCount == 0

                    igBeginDisabled(disabled)
                    
                    if igTreeNode($typeof(data)):
                          
                      listFieldsUi(data)

                      ent.addOrUpdate data

                      igTreePop()
                    
                    igEndDisabled()

              igPopItemWidth()
              igPopID()
        

      igEnd()