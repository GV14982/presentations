import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { readFileSync } from "node:fs";

const filteredMethods = [
  "window/showMessage",
  "window/logMessage",
]

function handleResponse(chunk: Buffer) {
  const stringData = chunk.toString("utf-8")
  const [header, msgContent] = stringData.split("\r\n\r\n")
  if (!header || !msgContent) {
    throw new Error(`Invalid message... HEADER:${header}, CONTENT:${msgContent}`)
  }
  const content = JSON.parse(msgContent)
  if ("method" in content && !filteredMethods.includes(content.method) || "id" in content) {
    console.log("===New Message===\n", stringData, "\n")
  }

}

function initialize() {
  return JSON.stringify({ jsonrpc: "2.0", id: 1, method: "initialize" });
}
function initialized() {
  return JSON.stringify({ jsonrpc: "2.0", method: "initialized" });
}

function openFile(path: string) {
  const file = readFileSync(path);
  return JSON.stringify({
    jsonrpc: "2.0",
    method: "textDocument/didOpen",
    params: {
      uri: `file://${process.cwd()}/main.go`,
      languageId: "go",
      version: 1,
      text: file.toString()
    }
  })
}

function waitForResponseFunc<T>(lsp: ChildProcessWithoutNullStreams, res: (arg?: T | PromiseLike<T>) => void, id: string | number) {
  return (chunk: Buffer) => {
    const [_header, content] = chunk.toString("utf-8").split("\r\n\r\n", 2)
    if (!content) {
      return;
    }
    const parsed = JSON.parse(content);
    if ("id" in parsed && (typeof parsed.id === "string" || typeof parsed.id === "number")) {
      lsp.stdout.off("data", waitForResponseFunc(lsp, res, id))
      return res();
    }
  }
}

function writeMsg(content: string, lsp: ChildProcessWithoutNullStreams, waitForResponse: boolean): Promise<void> {
  const size = Buffer.from(content).length
  const msg = `Content-Length: ${size}\r\n\r\n${content}`
  const parsed = JSON.parse(content);
  const shouldWait = waitForResponse && "id" in parsed && (typeof parsed.id === "string" || typeof parsed.id === "number");
  return new Promise((res) => {
    console.log("+++Writing Message+++\n", msg, "\n")
    if (shouldWait) {
      lsp.stdout.on("data", waitForResponseFunc(lsp, res, parsed.id))
    }
    lsp.stdin.write(msg, !shouldWait ? () => res() : undefined)
  })
}

async function main() {
  const lsp = spawn("gopls", ["serve"])
  lsp.stderr.on("data", chunk => console.error(`${chunk}`))
  lsp.stdout.on("data", handleResponse)
  await writeMsg(initialize(), lsp, true)
  await writeMsg(initialized(), lsp, false)
  await writeMsg(openFile("./main.go"), lsp, false)
  await writeMsg(openFile("./other.go"), lsp, false)
}

main()
