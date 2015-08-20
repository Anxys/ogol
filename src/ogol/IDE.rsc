module ogol::IDE

import util::IDE;
import ogol::Syntax;
import ParseTree;

void main() {
  registerLanguage("Ogol", "ogol", start[Program](str src, loc l) {
    return parse(#start[Program], src, l);
  });
}