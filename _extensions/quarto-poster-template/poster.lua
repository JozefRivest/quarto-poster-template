-- Poster layout filter.
--
-- Turns author-friendly markdown into beamerposter LaTeX:
--
--   ::: column          -> \separatorcolumn \begin{column}{\colwidth} ... \end{column}
--   ## Heading          -> \begin{block}{Heading} ... \end{block}
--   ## Heading {.alert}  -> \begin{alertblock}{Heading} ... \end{alertblock}
--   ## Heading {.example}-> \begin{exampleblock}{Heading} ... \end{exampleblock}
--   ### Sub-heading      -> \heading{Sub-heading}   (inside a block)
--
-- Content before the first `##` inside a column is emitted as-is.

local function raw(s)
  return pandoc.RawBlock("latex", s)
end

local function block_env(header)
  if header.classes:includes("alert") then
    return "alertblock"
  elseif header.classes:includes("example") then
    return "exampleblock"
  else
    return "block"
  end
end

function Div(el)
  if not el.classes:includes("column") then
    return nil
  end

  local out = pandoc.List:new()
  out:insert(raw("\\separatorcolumn"))
  out:insert(raw("\\begin{column}{\\colwidth}"))

  local cur_title = nil
  local cur_env = nil
  local cur_body = pandoc.List:new()

  local function flush()
    if cur_title ~= nil then
      out:insert(raw("\\begin{" .. cur_env .. "}{" .. cur_title .. "}"))
    end
    for _, b in ipairs(cur_body) do
      out:insert(b)
    end
    if cur_title ~= nil then
      out:insert(raw("\\end{" .. cur_env .. "}"))
    end
    cur_title = nil
    cur_env = nil
    cur_body = pandoc.List:new()
  end

  for _, b in ipairs(el.content) do
    if b.t == "Header" and b.level == 2 then
      flush()
      cur_title = pandoc.utils.stringify(b.content)
      cur_env = block_env(b)
    elseif b.t == "Header" and b.level >= 3 then
      cur_body:insert(raw("\\heading{" .. pandoc.utils.stringify(b.content) .. "}"))
    else
      cur_body:insert(b)
    end
  end
  flush()

  out:insert(raw("\\end{column}"))
  return out
end
