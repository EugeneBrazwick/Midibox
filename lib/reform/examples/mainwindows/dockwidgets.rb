
# Copyright (c) 2010 Eugene Brazwick
=begin
 ** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 ** All rights reserved.
 ** Contact: Nokia Corporation (qt-info@nokia.com)


 For the full example + license + copyright info see:

    http://doc.qt.nokia.com/4.6/mainwindows-dockwidgets-mainwindow-cpp.html

  and

    http://doc.qt.nokia.com/4.6/mainwindows-dockwidgets.html


=end

require 'reform/app'

ImgPath = File.dirname(__FILE__) + '/images/'

Reform::app {
  mainwindow {
    title tr('Dock Widgets')
    textedit {
      name :textEdit
    }
    menuBar {
      menu {
        text tr('&File')
        action {
          name :newLetterAct
          text tr('&New')
          icon ImgPath + 'new.png'
          shortcut :new
          statustip tr('Create a new form letter')
          whenClicked do  # FIXME: this is an UGLY codeblurb:
            textEdit.clear
            cursor = textEdit.textCursor
            cursor.movePosition Qt::TextCursor::Start
            topFrame = cursor.currentFrame
            topFrameFormat = topFrame.frameFormat
            topFrameFormat.padding = 16
            topFrame.frameFormat = topFrameFormat
            textFormat = Qt::TextCharFormat.new
            boldFormat = Qt::TextCharFormat.new
            boldFormat.fontWeight = Qt::Font::Bold
            italicFormat = Qt::TextCharFormat.new
            italicFormat.fontItalic = true
            tableFormat = Qt::TextTableFormat.new
            tableFormat.border = 1
            tableFormat.cellPadding = 16
            tableFormat.margin = 4
            tableFormat.alignment = Qt::AlignRight
            cursor.insertTable(1, 1, tableFormat)
            cursor.insertText('The Firm', boldFormat)
            cursor.insertBlock
            cursor.insertText('321 City Street', textFormat)
            cursor.insertBlock
            cursor.insertText('Industry Park')
            cursor.insertBlock
            cursor.insertText 'Some Country'
            cursor.position = topFrame.lastPosition
            cursor.insertText(Qt::Date::currentDate.toString('d MMMM yyyy'), textFormat)
            cursor.insertBlock
            cursor.insertBlock
            cursor.insertText('Dear ', textFormat)
            cursor.insertText('NAME', italicFormat)
            cursor.insertText(',', textFormat)
            3.times do cursor.insertBlock end
            cursor.insertText(tr('Yours sincerely,'), textFormat)
            3.times do cursor.insertBlock end
            cursor.insertText('The Boss', textFormat)
            cursor.insertBlock
            cursor.insertText('ADDRESS', italicFormat)
          end
        }
        action {
          name :saveAct
          text tr('&Save...')
          icon ImgPath + 'save.png'
          shortcut :save
          statustip tr('Save the current form letter')
          whenClicked do
            fileName = Qt::FileDialog::getSaveFileName(@qtc, tr('Choose a file name'), '.',
                                                       tr('HTML (*.html *.htm)'))
            break unless fileName
            file = Qt::File.new(fileName)
            unless file.open(Qt::File::WriteOnly | Qt::File::Text)
              Qt::MessageBox::warning(@qtc, tr('Dock Widgets'),
                                      tr("Cannot write file %s:\n%s.") % [fileName, file.errorString])
              break
            end
            out = Qt::TextStream.new(file)
            Qt::Application::overrideCursor = Qt::WaitCursor
            out << textEdit.toHtml
            Qt::Application::restoreOverrideCursor
            statusBar.message(tr("Saved '%s'") % fileName, 2000)
          end
        }
        action {
          name :printAct
          text tr('&Print...')
          icon ImgPath + 'print.png'
          shortcut :print
          statustip 'Print the current form letter'
          whenClicked do
            document = textEdit.document
            printer = Qt::Printer.new
            dlg = Qt::PrintDialog.new(printer, @qtc)
            # using break or return is *both* illegal in ruby. They cause a LocalJumpError so...
            # let's ignore that error.
            return unless dlg.exec == Qt::Dialog::Accepted
            document.print(printer)
            statusBar.message(tr('Ready'), 2000)
          end
        }
        separator
        quiter
      }
      menu {
        text tr('&Edit')
        action {
          name :undoAct
          text tr('&Undo')
          icon ImgPath + 'undo.png'
          shortcut :undo
          statustip tr('Undo the last editing action')
          whenClicked { textEdit.document.undo }
        }
      }
      menu {
        text tr('&View')
        name :viewMenu
      }
      separator
      menu {
        text tr('&Help')
        action { #about
          title tr('About')
          statustip tr("Show the application's About box")
          whenClicked do
            Qt::MessageBox::about(@qtc, tr('About Dock Widgets'),
                                  tr("The <b>Dock Widgets</b> example demonstrates how to " +
                                      "use Qt's dock widgets. You can enter your own text, " +
                                      "click a customer to add a customer name and " +
                                      "address, and click standard paragraphs to add them."))
          end
        }
        action { #aboutQt
          title tr('About &Qt')
          statustip tr("Show the Qt library's About box")
          whenClicked { $qApp.aboutQt }
        }
      } # helpmenu
    } # menuBar
    toolbar { # file
      text tr('File')
      actions :newLetterAct, :saveAct, :printAct
    }
    toolbar { # edit
      text tr('Edit')
      # NOTE: you cannot say 'action' here. Obviously.
      actions :undoAct
    }
    statusBar {
      message tr('Ready')
    }
    dock {
      title tr('Customers')
      allowedAreas :left, :right # Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea
      area :right
      viewmenu :viewMenu
      # NOTE: the example uses a QListWidget, and this is a QListView(!)
      list {
        name :customerList
        ruby_model {
          value 'John Doe, Harmony Enterprises, 12 Lakeside, Ambleton',
                'Jane Doe, Memorabilia, 23 Watersedge, Beaton',
                'Tammy Shea, Tiblanka, 38 Sea Views, Carlton',
                'Tim Sheen, Caraba Gifts, 48 Ocean Way, Deal',
                'Sol Harvey, Chicos Coffee, 53 New Springs, Eccleston',
                'Sally Hobart, Tiroli Tea, 67 Long River, Fedula'
        }
        whenCurrentChanged do |index, prev|
          customer = index.data.value
#           tag "whenCurrentChanged customer = '#{customer}'"
          break if customer.empty?
          customerList = customer.split(', ')
          document = textEdit.document
          cursor = document.find('NAME')
          unless cursor.null?
            cursor.beginEditBlock
            cursor.insertText(customerList[0])
            oldcursor = cursor
            cursor = document.find('ADDRESS')
            unless cursor.null?
              customerList.each_with_index do |cust, i|
                next if i == 0
                cursor.insertBlock
                cursor.insertText(cust)
              end
              cursor.endEditBlock
            else
              oldcursor.endEditBlock
            end
          end
        end
      } # list
    } # Customers dock
    dock {
      title tr('Paragraphs')
      list { # note: this is not the same widget as in the example
        name :paragraphsList
        ruby_model value: ['Thank you for your payment which we have received today.',
                           'Your order has been dispatched and should be with you ' +
                             'within 28 days.',
                           'We have dispatched those items that were in stock. The ' +
                             "rest of your order will be dispatched once all the " +
                             "remaining items have arrived at our warehouse. No " +
                             "additional shipping charges will be made.",
                           "You made a small overpayment (less than $5) which we " +
                             "will keep on account for you, or return at your request.",
                           "You made a small underpayment (less than $1), but we have " +
                             "sent your order anyway. We'll add this underpayment to " +
                             "your next bill.",
                           "Unfortunately you did not send enough money. Please remit " +
                             "an additional $. Your order will be dispatched as soon as " +
                             "the complete amount has been received.",
                           "You made an overpayment (more than $5). Do you wish to " +
                             "buy more items, or should we return the excess to you?"]
        whenCurrentChanged do |index, prev|
          paragraph = index.data.value
          break if paragraph.empty?
          document = textEdit.document
          cursor = document.find(tr('Yours sincerely,'))
          break if cursor.null?
          cursor.beginEditBlock
          cursor.movePosition(Qt::TextCursor::PreviousBlock, Qt::TextCursor::MoveAnchor, 2)
          cursor.insertBlock
          cursor.insertText paragraph
          cursor.insertBlock
          cursor.endEditBlock
        end
      } # list
      area :right
      viewMenu :viewMenu
    } # Paragraphs dock
    whenShown {
      newLetterAct.whenClicked
    }
  } #Mainwindow
} # application