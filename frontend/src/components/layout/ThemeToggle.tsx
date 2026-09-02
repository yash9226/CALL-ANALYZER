import { Moon, Sun } from "lucide-react";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";

export function ThemeToggle({ collapsed }: { collapsed?: boolean }) {
  const [dark, setDark] = useState(() => document.documentElement.classList.contains("dark"));

  useEffect(() => {
    document.documentElement.classList.toggle("dark", dark);
    localStorage.setItem("theme", dark ? "dark" : "light");
  }, [dark]);

  return (
    <Button
      variant="ghost"
      size={collapsed ? "icon-sm" : "sm"}
      onClick={() => setDark((d) => !d)}
      className="w-full justify-start text-muted-foreground"
      aria-label={dark ? "Switch to light theme" : "Switch to dark theme"}
    >
      {dark ? <Moon /> : <Sun />}
      {!collapsed && <span>{dark ? "Dark" : "Light"}</span>}
    </Button>
  );
}
