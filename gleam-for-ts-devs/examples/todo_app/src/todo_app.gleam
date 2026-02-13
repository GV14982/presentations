import banner.{format_banner}
import gleam/int
import gleam/io
import gleam/list
import util.{clear_screen, enumerate, halt, prompt, wrap_in_color}

type Todo {
  Uncompleted(name: String)
  Completed(name: String)
}

pub fn main() {
  main_menu([
    Uncompleted("Walk the dog"),
    Uncompleted("Do the dishes"),
    Completed("Learn Gleam"),
    Uncompleted("Plan a date night"),
  ])
}

fn print_todos(todos: List(Todo)) {
  todos
  |> enumerate
  |> list.each(fn(v) {
    let #(i, todo_item) = v
    case todo_item {
      Completed(_) -> io.print("✅ #")
      Uncompleted(_) -> io.print("   #")
    }
    io.println(i + 1 |> int.to_string <> ". " <> todo_item.name)
  })
}

fn main_menu(todos: List(Todo)) {
  clear_screen()
  io.println(format_banner())
  print_todos(todos)
  io.println(format_menu())
  let val = prompt("What would you like to do? ")
  let todos = case val {
    "a" -> add_todo(todos)
    "c" -> complete_todo(todos)
    "d" -> delete_todo(todos)
    "e" -> {
      halt()
      todos
    }
    _ -> {
      io.println("INVALID")
      todos
    }
  }
  main_menu(todos)
}

fn add_todo(todos: List(Todo)) -> List(Todo) {
  let val = prompt("Todo name? ")
  [Uncompleted(val), ..todos]
}

fn delete_todo(todos: List(Todo)) -> List(Todo) {
  let val = prompt("Todo number? ")
  case val |> int.parse {
    Error(_) -> {
      io.println("Invalid input, must input a number")
      todos
    }
    Ok(num) ->
      todos
      |> enumerate
      |> list.filter_map(fn(item) {
        let #(i, val) = item
        case i + 1 != num {
          True -> Ok(val)
          False -> Error(Nil)
        }
      })
  }
}

fn complete_todo(todos: List(Todo)) -> List(Todo) {
  let val = prompt("Todo number? ")
  case val |> int.parse {
    Error(_) -> {
      io.println("Invalid input, must input a number")
      todos
    }
    Ok(num) ->
      todos
      |> enumerate
      |> list.filter_map(fn(item) {
        let #(i, val) = item
        case i + 1 != num {
          True -> Ok(val)
          False -> Ok(Completed(val.name))
        }
      })
  }
}

fn format_menu() -> String {
  "
  (" <> wrap_in_color("a", 4) <> ")dd new todo
  (" <> wrap_in_color("c", 2) <> ")omplete todo
  (" <> wrap_in_color("d", 3) <> ")elete todo
  (" <> wrap_in_color("e", 1) <> ")xit
  "
}
