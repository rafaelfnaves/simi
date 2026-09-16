import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
// The account owns the preference, so every change is submitted to the server
// and the layout renders the class on `<html>`. This controller covers what the
// server cannot: Turbo replaces the body but never the attributes of `<html>`,
// so the class has to be put back after each render, and an account that
// follows the system depends on the browser to resolve which theme that is.
export default class extends Controller {
  static targets = ["field"]
  static values = { preference: String }

  connect() {
    this.paint(this.resolvedTheme())
    this.fieldTarget.value = this.otherTheme()
  }

  apply(event) {
    event.preventDefault()

    const theme = this.otherTheme()
    this.fieldTarget.value = theme
    this.paint(theme)

    this.element.requestSubmit()
  }

  resolvedTheme() {
    if (this.preferenceValue === "light" || this.preferenceValue === "dark") {
      return this.preferenceValue
    }

    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  otherTheme() {
    return document.documentElement.classList.contains("dark") ? "light" : "dark"
  }

  paint(theme) {
    const root = document.documentElement
    root.classList.toggle("dark", theme === "dark")
    root.classList.toggle("light", theme === "light")
  }
}
