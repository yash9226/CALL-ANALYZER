import {
  AudioLines,
  ChevronLeft,
  LayoutDashboard,
  MessageSquareText,
  PhoneCall,
  SlidersHorizontal,
} from "lucide-react";
import { useEffect, useState } from "react";
import { NavLink } from "react-router-dom";
import { ThemeToggle } from "./ThemeToggle";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const NAV = [
  { to: "/", label: "Dashboard", icon: LayoutDashboard, end: true },
  { to: "/calls", label: "Calls", icon: PhoneCall },
  { to: "/admin", label: "Framework", icon: SlidersHorizontal },
  { to: "/chat", label: "Assistant", icon: MessageSquareText },
];

export function Sidebar() {
  const [collapsed, setCollapsed] = useState(
    () => localStorage.getItem("sidebar") === "collapsed",
  );

  useEffect(() => {
    localStorage.setItem("sidebar", collapsed ? "collapsed" : "expanded");
  }, [collapsed]);

  return (
    <aside
      className={cn(
        "sticky top-0 flex h-screen shrink-0 flex-col border-r border-border bg-card transition-[width] duration-200",
        collapsed ? "w-16" : "w-60",
      )}
    >
      <div className="flex h-14 items-center gap-2 border-b border-border px-4">
        <AudioLines className="size-5 shrink-0 text-primary" />
        {!collapsed && (
          <span className="truncate text-[15px] font-bold tracking-tight">CALL-ANALYZER</span>
        )}
      </div>

      <nav className="flex-1 space-y-0.5 p-2">
        {NAV.map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            title={collapsed ? label : undefined}
            className={({ isActive }) =>
              cn(
                "flex items-center gap-2.5 rounded-md border-l-2 border-transparent px-2.5 py-2 text-[13px] transition-colors",
                isActive
                  ? "border-l-primary bg-primary/10 font-medium text-primary"
                  : "text-muted-foreground hover:bg-accent hover:text-foreground",
              )
            }
          >
            <Icon className="size-4 shrink-0" />
            {!collapsed && <span className="truncate">{label}</span>}
          </NavLink>
        ))}
      </nav>

      <div className="space-y-1 border-t border-border p-2">
        <ThemeToggle collapsed={collapsed} />
        <Button
          variant="ghost"
          size={collapsed ? "icon-sm" : "sm"}
          onClick={() => setCollapsed((c) => !c)}
          className="w-full justify-start text-muted-foreground"
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
        >
          <ChevronLeft className={cn("transition-transform", collapsed && "rotate-180")} />
          {!collapsed && <span>Collapse</span>}
        </Button>

        {!collapsed && (
          <div className="flex items-center gap-2 rounded-md px-2 py-2">
            <div className="flex size-7 shrink-0 items-center justify-center rounded-full bg-primary/15 text-2xs font-semibold text-primary">
              DK
            </div>
            <div className="min-w-0">
              <p className="truncate text-xs font-medium">Deep Kakadiya</p>
              <p className="text-2xs text-muted-foreground">Admin</p>
            </div>
          </div>
        )}
      </div>
    </aside>
  );
}
