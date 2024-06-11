import polymorph, ../../core, ../g2/imgui

onEcsBuilt:
  var entityEditorShown: bool

  proc showEntityEditor*(toggleKey = keyF2) =
    if toggleKey.tapped:
      entityEditorShown = not entityEditorShown

    if entityEditorShown:
    
      igBegin("Entities", addr entityEditorShown)

      if entityCount() != 0:
        for i in 0 ..< entityStorage.nextEntityId.int:
          let ent = (i.EntityId).makeRef

          if ent.alive and igCollapsingHeader("Entity: " & $ent.entityId.int):
            igPushID(ent.entityId.int32)

            #igText($ent)

            if ent.componentCount > 0:
              for compRef in ent.components:
                caseComponent(compRef.typeId):
                  #TODO: delete button

                  var data = componentInstanceType()(compRef.index.int).access
                  
                  if igTreeNode($typeof(data)):

                    #igText $data

                    template listFields(obj: untyped): untyped = 
                      for field, value in obj.fieldpairs:
                        when value is int or value is int32:
                          igInputInt(field, addr value)
                        elif value is float32:
                          igInputFloat(field, addr value)
                        elif value is Vec2:
                          igInputFloat2(field, value)
                        elif value is Vec2i:
                          igInputInt2(field, value)
                        elif value is Rect:
                          igInputFloat4(field, value)
                        elif value is Color:
                          igColorEdit4(field, value)
                        elif value is bool:
                          igCheckbox(field, addr value)
                        elif value is string:
                          igInputText(field, value)
                        elif value is object:
                          if igTreeNode(field):
                            listFields(value)
                            igTreePop()
                        elif compiles($value):
                          igText(field & ": " & $value)
                        else:
                          igText(field)

                    listFields(data)

                    ent.addOrUpdate data

                    igTreePop()

            igPopID()
        

      igEnd()