import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/string

const ansi_escape = "\u{001b}"

pub fn prompt(display: String) -> String {
  let assert Ok(val) = erlang.get_line(display)
  val |> string.trim
}

pub fn enumerate(on: List(t)) -> List(#(Int, t)) {
  on |> list.index_map(fn(item, i) { #(i, item) })
}

pub fn wrap_in_color(text: String, color: Int) -> String {
  ansi_escape
  <> "[38;5;"
  <> color |> int.to_string
  <> "m"
  <> text
  <> ansi_escape
  <> "[0m"
}

pub fn clear_screen() -> Nil {
  io.print(ansi_escape <> "c")
}

@external(erlang, "erlang", "halt")
pub fn halt() -> Nil
