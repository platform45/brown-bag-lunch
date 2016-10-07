defmodule Slime.Parser do
  @moduledoc """
  Build a Slime tree from a Slime document.
  """

  alias Slime.Doctype
  alias Slime.Parser.AttributesKeyword

  @content  "|"
  @comment  "/"
  @html     "<"
  @preserved"'"
  @script   "-"
  @smart    "="

  @attr_delim_regex ~r/[ ]+(?=([^"]*"[^"]*")*[^"]*$)/
  @attr_group_regex ~r/(?:\s*[\w-]+\s*=\s*(?:[^\s"'][^\s]+[^\s"']|"(?:(?<z>\{(?:[^{}]|\g<z>)*\})|[^"])*"|'[^']*'))*/
  @tag_regex ~r/\A(?<tag>[\w-]*)?(?<css>(?:[\.|#][\w-]*)*)?(?<leading_space>\<)?(?<trailing_space>\>)?/
  @id_regex ~r/(?:#(?<id>[\w-]*))/
  r = ~r/(^|\G)(?:\\.|[^#]|#(?!\{)|(?<pn>#\{(?:[^"}]++|"(?:\\.|[^"#]|#(?!\{)|(?&pn))*")*\}))*?\K"/u
  @quote_outside_interpolation_regex r
  @verbatim_text_regex ~r/^(\s*)([#{@content}#{@preserved}])\s?/
  @eex_line_regex ~r/^(\s*)(-|=|==)\s*(.*?)$/

  @merge_attrs %{class: " "}

  def parse_lines(lines, acc \\ [])

  def parse_lines([], result), do: Enum.reverse(result)
  def parse_lines([head | tail], result) do
    parsed_result =
      parse_verbatim_text(head, tail) ||
      parse_eex_lines(head, tail)     ||
      parse_line(head)

    case parsed_result do
      nil ->
        parse_lines(tail, result)

      {text, rest} when is_list(rest) ->
        parse_lines(rest, [text | result])

      text ->
        parse_lines(tail, [text | result])
    end
  end

  def parse_line(""), do: nil
  def parse_line(line) do
    case strip_line(line) do
      {_indentation, ""} -> nil
      {indentation, line} ->
        line = line
               |> String.first
               |> parse_line(line)

        {indentation, line}
    end
  end

  defp attribute_key(key), do: key |> String.strip |> String.to_atom
  defp attribute_val(~s'"' <> value) do
    value
    |> String.strip
    |> String.slice(0..-2)
    |> parse_eex_string
  end
  defp attribute_val(value), do: parse_eex(value, true)

  defp css_classes(""), do: []
  defp css_classes(input) do
    [""|t] = String.split(input, ".")
    [class: t]
  end

  defp html_attribute(key, value) do
    key = attribute_key(key)
    value = attribute_val(value)

    [{key, value}]
  end

  defp html_id(""), do: []
  defp html_id(id), do: [id: id]

  defp parse_comment("!" <> comment), do: {:html_comment, children: [String.strip(comment)]}
  defp parse_comment("[" <> comment) do
    [h|[t|_]] = comment |> String.split("]", parts: 2)
    conditions = String.strip(h)
    children = t |> String.strip |> parse_inline
    {:ie_comment, content: conditions, children: children}
  end
  defp parse_comment(_comment), do: ""

  defp parse_eex(input, inline \\ false) do
    input = String.lstrip(input)
    script = input
             |> String.split(~r/^(-|==|=)/)
             |> List.last
             |> String.lstrip
    inline = inline or String.starts_with?(input, "=")
    {:eex, content: script, inline: inline}
  end

  defp parse_eex_string(input) do
    if String.contains?(input, "\#{") do
      script = ~s("#{String.replace(input, @quote_outside_interpolation_regex, ~S(\\"))}")
      {:eex, content: script, inline: true}
    else
      input
    end
  end

  defp parse_attributes(""), do: {"", []}
  defp parse_attributes(nil), do: {"", []}
  defp parse_attributes("(" <> line), do: parse_wrapped_attributes(line, ")")
  defp parse_attributes("[" <> line), do: parse_wrapped_attributes(line, "]")
  defp parse_attributes("{" <> line), do: parse_wrapped_attributes(line, "}")
  defp parse_attributes(line) do
    match = @attr_group_regex |> Regex.run(line) |> List.first
    offset = String.length(match)
    {attrs, rem} = line |> String.split_at(offset)
    attrs = parse_attributes(attrs, [])
    {rem, attrs}
  end

  defp parse_attributes("", acc) do
    acc
  end
  defp parse_attributes(line, acc) when is_binary(line) do
    line
    |> String.split(@attr_delim_regex)
    |> parse_attributes(acc)
  end
  defp parse_attributes([], acc) do
    acc
  end
  defp parse_attributes([head|tail], acc) do
    parts = String.split(head, ~r/=/, parts: 2)
    attr = case parts do
             [key, value] -> html_attribute(key, value)
             [key]        -> html_attribute(key, "true")
             _            -> []
           end
    parse_attributes(tail, attr ++ acc)
  end

  defp parse_inline(""), do: []
  defp parse_inline(@smart <> content) do
    content
    |> parse_eex(true)
    |> List.wrap
  end
  defp parse_inline(input) do
    input
    |> String.strip(?")
    |> parse_eex_string
    |> List.wrap
  end

  defp parse_line("", _line),        do: ""
  defp parse_line(@content, line),   do: line |> String.slice(1..-1) |> String.strip |> parse_eex_string
  defp parse_line(@comment, line),   do: line |> String.slice(1..-1) |> parse_comment
  defp parse_line(@html, line),      do: line |> String.strip |> parse_eex_string
  defp parse_line(@preserved, line), do: line |> String.slice(1..-1) |> parse_eex_string
  defp parse_line(@script, line),    do: parse_eex(line)
  defp parse_line(@smart, line),     do: parse_eex(line, true)

  defp parse_line(_, "doctype " <> type) do
    value = Doctype.for(type)
    {:doctype, value}
  end

  defp parse_line(_, line) do
    line = String.strip(line)
    offset = case Regex.run(~r/[\s\(\[{=]/, line, return: :index) do
               [{index, _}] -> index
               nil -> String.length(line)
             end

    {head, tail} = String.split_at(line, offset)
    {tag, basics, spaces} = parse_tag(head)

    tail = if is_binary(tail), do: String.lstrip(tail), else: tail

    {children, attributes, close} = case parse_attributes(tail) do
                                      {"/", attributes} ->
                                        {[], Enum.reverse(attributes), true}
                                      {rem, attributes} ->
                                        children = rem
                                          |> String.strip
                                          |> parse_inline
                                        {children, Enum.reverse(attributes), false}
                                     end

    attributes = AttributesKeyword.merge(basics ++ attributes, @merge_attrs)
    {tag, attributes: attributes, children: children, spaces: spaces, close: close}
  end

  defp parse_tag(line) do
    parts = Regex.named_captures(@tag_regex, line)

    tag = case parts["tag"] do
            "" -> "div"
            tag -> tag
          end

    spaces = %{}
    if parts["leading_space"] != "", do: spaces = Dict.put(spaces, :leading, true)
    if parts["trailing_space"] != "", do: spaces = Dict.put(spaces, :trailing, true)

    case Regex.named_captures(@id_regex, parts["css"]) do
      nil ->
        {tag, css_classes(parts["css"]) ++ html_id(""), spaces}
      capture ->
        css_classes = String.replace(parts["css"], "#" <> capture["id"], "")
        {tag, css_classes(css_classes) ++ html_id(capture["id"]), spaces}
    end
  end

  defp parse_verbatim_text(head, tail) do
    case Regex.run(@verbatim_text_regex, head) do
      nil ->
        nil

      [text_indent, indent, text_type] ->
        indent = String.length(indent)
        text_indent = String.length(text_indent)
        {text_lines, rest} = parse_verbatim_text(indent, text_indent, head, tail)
        text = Enum.join(text_lines, "\n")
        if text_type == @preserved, do: text = text <> " "
        {{indent, parse_eex_string(text)}, rest}
    end
  end

  defp parse_verbatim_text(indent, text_indent, head, tail) do
    if String.length(head) == text_indent, do: text_indent = text_indent + 1
    {_, head_text} = String.split_at(head, text_indent)
    {text_lines, rest} = Enum.split_while(tail, fn (line) ->
      {line_indent, _} = strip_line(line)
      indent < line_indent
    end)
    text_lines = Enum.map(text_lines, fn (line) ->
      {_, text} = String.split_at(line, text_indent)
      text
    end)
    unless head_text == "", do: text_lines = [head_text | text_lines]
    {text_lines, rest}
  end

  defp parse_eex_lines(head, tail) do
    {indent, head} = strip_line(head)

    case Regex.run(@eex_line_regex, head, capture: :all_but_first) do
      nil ->
        nil

      [_, delim, content] ->
        {content, rest} = slurp_eex_lines("", [content | tail])
        inline? = @smart == String.first delim

        {{indent, {:eex, content: content, inline: inline?}}, rest}
    end
  end

  defp slurp_eex_lines(content, [head | tail]) do
    content = content <> head

    if String.last(head) in [",", "\\"] do
      slurp_eex_lines(content <> "\n", tail)
    else
      {content, tail}
    end
  end

  defp parse_wrapped_attributes(line, delim) do
    [attrs, rem] = line
                   |> String.strip
                   |> String.split(delim, parts: 2)

    attributes = parse_attributes(attrs, [])
    {rem, attributes}
  end

  defp strip_line(line) do
    orig_len = String.length(line)
    trimmed  = String.lstrip(line)
    trim_len = String.length(trimmed)

    offset = if trimmed == "- else", do: 2, else: 0
    {orig_len - trim_len + offset, trimmed}
  end

end
