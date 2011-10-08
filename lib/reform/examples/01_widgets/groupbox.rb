
# qtruby/reform version of example: http://doc.qt.nokia.com/4.6/widgets-groupbox.html
require 'reform/app'

Reform::app {
  title tr('Group Boxes')
  groupbox {
    title tr('Exclusive Radio Buttons')
    layoutpos 0, 0
    vbox {
      radio text: tr('&Radio button 1'), checked: true
      radio text: tr('&Radio button 2')
      radio text: tr('&Radio button 3')
      spacer stretch: 1
    }
  }
  groupbox {
    title tr('E&xclusive Radio Buttons')
    layoutpos 1, 0
    checkable true
    checked false
    vbox {
      radio text: tr('&Radio button 1'), checked: true
      radio text: tr('&Radio button 2')
      radio text: tr('&Radio button 3')
      checkbox text: tr('Ind&ependent checkbox'), checked: true
      spacer stretch: 1
    }
  }
  groupbox {
    title tr('Non-Exclusive Checkboxes')
    flat true
    vbox {
      checkbox text: tr('&Checkbox 1')
      checkbox text: tr('&Checkbox 2'), checked: true
      checkbox {
        text tr('Tri-&state button')
        tristate true
        partiallyChecked
      }
      spacer stretch: 1
    }
  }
  groupbox {
    title tr('&Push Buttons')
    checkable true
    checked true
    vbox {
      button text: tr('&Normal Button')
         # checking the button makes it checkable, Note that the default Lucid style
         # does not make it very clear whether the button is checked or not, so I would
         # not use this feature.
      button text: tr('&Toggle Button'), checked: true
      button text: tr('&Flat Button'), flat: true
      button {
        text tr('Pop&up Button')
        menu {
          action text: tr('&First Item')
          action text: tr('&Second Item')
          action text: tr('&Third Item')
          action text: tr('F&ourth Item')
          action {
            text tr('Submenu')
            menu {
              text tr('Popup Submenu')
              action text: tr('Item 1')
              action text: tr('Item 2')
              action text: tr('Item 3')
            }
          }
        }
      }
    }
  }
}

