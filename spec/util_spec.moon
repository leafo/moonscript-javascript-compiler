
describe "moonscript.javascript.util", ->
  describe "split_ntuples", ->
    import split_ntuples from require "moonscript.javascript.util"

    it "splits all items into size 1 tuples", ->
      assert.same {
        please: "sirs"
        rest: {
          "a", "b", "c", "d", "e"
        }
      }, split_ntuples!\transform {
        please: "sirs"
        "a", "b", "c", "d", "e"
      }

    it "splits items into size 1 tuples from offset", ->
      assert.same {
        please: "sirs"
        "a", "b"
        rest: {
          "c", "d", "e"
        }
      }, split_ntuples(3)\transform {
        please: "sirs"
        "a", "b", "c", "d", "e"
      }

    it "splits all items into size 2", ->
      assert.same {
        rest: {
          { "a", "b" }
          { "c", "d" }
          { "e" }
        }

      }, split_ntuples(1, 2)\transform {
        "a", "b", "c", "d", "e"
      }

    it "splits items into size 2 from offset", ->
      assert.same {
        "a"
        rest: {
          { "b", "c" }
          { "d", "e" }
        }

      }, split_ntuples(2, 2)\transform {
        "a", "b", "c", "d", "e"
      }

    it "splits items into size 3 from offset", ->
      assert.same {
        "a", hello: "world"
        rest: {
          {"b", "c", "d"}
          {"e"}
        }
      }, split_ntuples(2, 3)\transform {
        hello: "world"
        "a", "b", "c", "d", "e"
      }



