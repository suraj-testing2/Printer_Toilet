#library('web_utils');

#import('dart:html');
#import('../collab.dart', prefix: 'collab');
#import('web_client.dart');

class TextChangeEvent {
  final Element target;
  final String text;
  final int position;
  final String deleted;
  final String inserted;
  
  TextChangeEvent(this.target, this.text, this.position, this.deleted, this.inserted);
  
  String toString() => "TextChangeEvent {text: $text, position: $position, deleted: $deleted, inserted: $inserted}";
}

typedef void TextChangeHandler(TextChangeEvent e);

class TextChangeListener {
  final Element _element;
  final List<TextChangeHandler> _handlers;
  String _oldValue;
  
  TextChangeListener(this._element) 
    : _handlers = new List<TextChangeHandler>() {
    _element.on.keyUp.add((KeyboardEvent e) {
      int pos = _element.dynamic.selectionStart;
      _onChange();
    });
    _element.on.change.add((Event e) {
      int pos = _element.dynamic.selectionStart;
      _onChange();
    });
  }

  void addChangeHandler(TextChangeHandler handler) {
    _handlers.add(handler);
  }

  void reset() {
    _oldValue = _element.dynamic.value;
  }
  
  /*
   * This algorithm works because there can only be one contiguous change
   * as a result of typing or pasting. If a paste contains a common substring
   * with the pasted over text, this will not attempt to find it and make
   * more than one delete/insert pair. This is actually good because it
   * preserves user intention when used in an OT system.
   */
  void _onChange() {
    String newValue = _element.dynamic.value;

    if (newValue == _oldValue) {
      return;
    }

    int start = 0;
    int end = 0;
    int oldLength = _oldValue.length;
    int newLength = newValue.length;
    
    while ((start < oldLength) && (start < newLength)
        && (_oldValue[start] == newValue[start])) {
      start++;
    }
    while ((start + end < oldLength) && (start + end < newLength)
        && (_oldValue[oldLength - end - 1] == newValue[newLength - end - 1])) {
      end++;
    }
    
    String deleted = _oldValue.substring(start, oldLength - end);
    String inserted = newValue.substring(start, newLength - end);
    _oldValue = newValue;
    _fire(newValue, start, deleted, inserted);
  }
  
  void _fire(String text, int position, String deleted, String inserted) {
    TextChangeEvent event = new TextChangeEvent(_element, text, position, deleted, inserted);
    _handlers.forEach((handler) { handler(event); });
  }  
}

void makeEditable(Element element, CollabWebClient client) {
  print("makeEditable");
  TextChangeListener listener = new TextChangeListener(element);

  bool listen = true;
  listener.addChangeHandler((TextChangeEvent event) {    
    print(event);
    if (listen) {
      listen = false;
      collab.TextOperation op = 
          new collab.TextOperation(client.id, "test", client.docVersion, event.position, event.deleted, event.inserted);
      client.queue(op);
      listen = true;
    }
  });
  
  client.document.addChangeHandler((collab.DocumentChangeEvent event) {
    if (listen) {
      listen = false;
      int cursorPos = element.dynamic.selectionStart;
      element.dynamic.value = event.text;
      if (event.position < cursorPos) {
        cursorPos = Math.max(0, cursorPos + event.inserted.length - event.deleted.length);
      }
      element.dynamic.setSelectionRange(cursorPos, cursorPos);
      listener.reset();
      listen = true;
    }
  });
}
