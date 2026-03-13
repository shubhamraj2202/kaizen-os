import { useState, useEffect } from “react”;

const habits = [
{ id: 1, name: “Early Start”, emoji: “⏰”, streak: 12, color: “#00E5C8” },
{ id: 2, name: “Gym”, emoji: “💪”, streak: 8, color: “#00E5C8” },
{ id: 3, name: “Learn Something”, emoji: “🧠”, streak: 5, color: “#00E5C8” },
{ id: 4, name: “Deep Work”, emoji: “🎧”, streak: 3, color: “#FF6B6B” },
{ id: 5, name: “No Socials AM”, emoji: “📵”, streak: 7, color: “#FF6B6B” },
{ id: 6, name: “Track Money”, emoji: “💰”, streak: 15, color: “#00E5C8” },
];

const weekDays = [“M”, “T”, “W”, “T”, “F”, “S”, “S”];
const heatmapData = Array.from({ length: 28 }, () => ({
done: Math.random() > 0.3,
partial: Math.random() > 0.6,
}));

const tasks = [
{ text: “Review weekly goals”, category: “Planning” },
{ text: “Plan tomorrow’s top 3”, category: “Planning” },
{ text: “Admin catch-up”, category: “Work” },
{ text: “Send project update”, category: “Work” },
{ text: “Light workout or stretch”, category: “Health” },
{ text: “Log weekly progress”, category: “Tracking” },
];

const mindsetData = [
{ day: “M”, energy: 70, focus: 85, mood: 60 },
{ day: “T”, energy: 80, focus: 70, mood: 75 },
{ day: “W”, energy: 60, focus: 90, mood: 80 },
{ day: “T”, energy: 90, focus: 85, mood: 70 },
{ day: “F”, energy: 75, focus: 65, mood: 85 },
{ day: “S”, energy: 85, focus: 80, mood: 90 },
{ day: “S”, energy: 65, focus: 75, mood: 65 },
];

function Ring({ pct, size = 80, stroke = 8, color = “#00E5C8” }) {
const r = (size - stroke) / 2;
const circ = 2 * Math.PI * r;
const dash = (pct / 100) * circ;
return (
<svg width={size} height={size} style={{ transform: “rotate(-90deg)” }}>
<circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={stroke} />
<circle cx={size/2} cy={size/2} r={r} fill=“none” stroke={color} strokeWidth={stroke}
strokeDasharray={`${dash} ${circ}`} strokeLinecap=“round”
style={{ filter: `drop-shadow(0 0 6px ${color})`, transition: “stroke-dasharray 1s ease” }} />
<text x={size/2} y={size/2+1} textAnchor=“middle” dominantBaseline=“middle”
style={{ transform: `rotate(90deg)`, transformOrigin: `${size/2}px ${size/2}px`,
fill: “#fff”, fontSize: size*0.2, fontFamily:”‘DM Sans’,sans-serif”, fontWeight:700 }}>
{pct}%
</text>
</svg>
);
}

const SCREENS = [“Dashboard”, “Habits”, “Tasks”, “Mindset”];

export default function App() {
const [screen, setScreen] = useState(0);
const [checkedHabits, setCheckedHabits] = useState([0, 1, 2, 5]);
const [checkedTasks, setCheckedTasks] = useState([0, 1]);
const [animIn, setAnimIn] = useState(true);

useEffect(() => {
setAnimIn(false);
const t = setTimeout(() => setAnimIn(true), 40);
return () => clearTimeout(t);
}, [screen]);

const toggleHabit = (i) => setCheckedHabits(p => p.includes(i) ? p.filter(x=>x!==i) : […p,i]);
const toggleTask  = (i) => setCheckedTasks(p  => p.includes(i) ? p.filter(x=>x!==i) : […p,i]);
const donePct = Math.round((checkedHabits.length / habits.length) * 100);

return (
<div style={{
minHeight:“100vh”, background:”#090E1A”,
display:“flex”, alignItems:“center”, justifyContent:“center”,
fontFamily:”‘DM Sans’,sans-serif”,
backgroundImage:“radial-gradient(ellipse at 20% 20%,rgba(0,229,200,0.07) 0%,transparent 60%),radial-gradient(ellipse at 80% 80%,rgba(100,80,255,0.07) 0%,transparent 60%)”,
}}>
<style>{`@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700;800&family=Space+Grotesk:wght@700&display=swap'); *{box-sizing:border-box;margin:0;padding:0} ::-webkit-scrollbar{display:none} .screen{animation:fadeUp .3s cubic-bezier(.4,0,.2,1) both} @keyframes fadeUp{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}} .row:hover{background:rgba(255,255,255,0.06)!important} .nav-btn{transition:all .2s;cursor:pointer;background:none;border:none} .nav-btn:hover{transform:scale(1.1)}`}</style>

```
  {/* iPhone Frame */}
  <div style={{
    width:375, height:812, background:"#0D1321", borderRadius:50, overflow:"hidden",
    position:"relative", display:"flex", flexDirection:"column",
    boxShadow:"0 40px 120px rgba(0,0,0,.8),0 0 0 1px rgba(255,255,255,.08),inset 0 0 0 2px rgba(255,255,255,.04)",
  }}>
    {/* Status Bar */}
    <div style={{padding:"14px 28px 0",display:"flex",justifyContent:"space-between",alignItems:"center",flexShrink:0}}>
      <span style={{color:"#fff",fontSize:14,fontWeight:600}}>9:41</span>
      <div style={{width:120,height:28,background:"#000",borderRadius:20,position:"absolute",left:"50%",transform:"translateX(-50%)",top:8}}/>
      <div style={{display:"flex",gap:6,alignItems:"center"}}>
        <div style={{display:"flex",gap:2,alignItems:"flex-end"}}>
          {[6,10,14,18].map((h,i)=><div key={i} style={{width:3,height:h,background:"#fff",borderRadius:2,opacity:0.5+i*0.15}}/>)}
        </div>
        <div style={{width:24,height:12,border:"1px solid rgba(255,255,255,.5)",borderRadius:3,padding:2,display:"flex"}}>
          <div style={{width:"80%",background:"#34C759",borderRadius:2}}/>
        </div>
      </div>
    </div>

    {/* Content */}
    <div style={{flex:1,overflowY:"auto",overflowX:"hidden",padding:"8px 0 0"}}>
      {animIn && (
        <div className="screen" key={screen}>
          {screen===0 && <DashboardScreen donePct={donePct} checkedHabits={checkedHabits}/>}
          {screen===1 && <HabitsScreen checkedHabits={checkedHabits} toggleHabit={toggleHabit}/>}
          {screen===2 && <TasksScreen checkedTasks={checkedTasks} toggleTask={toggleTask}/>}
          {screen===3 && <MindsetScreen data={mindsetData}/>}
        </div>
      )}
    </div>

    {/* Tab Bar */}
    <div style={{
      background:"rgba(13,19,33,.97)",backdropFilter:"blur(20px)",
      borderTop:"1px solid rgba(255,255,255,.06)",
      padding:"12px 0 28px",display:"flex",justifyContent:"space-around",flexShrink:0,
    }}>
      {[{icon:"⬡",label:"Home"},{icon:"◎",label:"Habits"},{icon:"✓",label:"Tasks"},{icon:"〜",label:"Mindset"}].map((t,i)=>(
        <button key={i} className="nav-btn" onClick={()=>setScreen(i)} style={{
          display:"flex",flexDirection:"column",alignItems:"center",gap:4,padding:"4px 16px",
          opacity:screen===i?1:0.4,
        }}>
          <span style={{fontSize:20,color:screen===i?"#00E5C8":"#fff",filter:screen===i?"drop-shadow(0 0 6px #00E5C8)":"none"}}>{t.icon}</span>
          <span style={{fontSize:10,color:screen===i?"#00E5C8":"rgba(255,255,255,.5)",fontWeight:600,letterSpacing:.5}}>{t.label}</span>
        </button>
      ))}
    </div>
  </div>
</div>
```

);
}

/* ─── DASHBOARD ─── */
function DashboardScreen({ donePct, checkedHabits }) {
return (
<div style={{padding:“0 20px 20px”}}>
<div style={{display:“flex”,justifyContent:“space-between”,alignItems:“flex-start”,marginBottom:24,paddingTop:8}}>
<div>
<p style={{color:“rgba(255,255,255,.4)”,fontSize:13,marginBottom:2}}>Friday, March 13</p>
<h1 style={{color:”#fff”,fontSize:26,fontWeight:800,fontFamily:”‘Space Grotesk’,sans-serif”,letterSpacing:-.5}}>
改善 Kaizen OS
</h1>
</div>
<div style={{width:42,height:42,borderRadius:14,background:“linear-gradient(135deg,#00E5C8,#6450FF)”,display:“flex”,alignItems:“center”,justifyContent:“center”,color:”#000”,fontWeight:800,fontSize:16}}>K</div>
</div>

```
  {/* Day Score */}
  <div style={{background:"linear-gradient(135deg,rgba(0,229,200,.15),rgba(100,80,255,.15))",border:"1px solid rgba(0,229,200,.2)",borderRadius:24,padding:20,marginBottom:16,display:"flex",alignItems:"center",gap:20}}>
    <Ring pct={donePct} size={90} stroke={9} color="#00E5C8"/>
    <div style={{flex:1}}>
      <p style={{color:"rgba(255,255,255,.5)",fontSize:12,marginBottom:4,letterSpacing:.8}}>TODAY'S SCORE</p>
      <p style={{color:"#fff",fontSize:32,fontWeight:800,fontFamily:"'Space Grotesk',sans-serif"}}>{donePct}%</p>
      <div style={{display:"flex",gap:8,marginTop:8,flexWrap:"wrap"}}>
        <span style={{background:"rgba(0,229,200,.15)",color:"#00E5C8",padding:"3px 10px",borderRadius:20,fontSize:11,fontWeight:600}}>🔥 {checkedHabits.length}/{habits.length} habits</span>
        <span style={{background:"rgba(255,107,107,.15)",color:"#FF6B6B",padding:"3px 10px",borderRadius:20,fontSize:11,fontWeight:600}}>3 tasks left</span>
      </div>
    </div>
  </div>

  {/* Stats */}
  <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:10,marginBottom:16}}>
    {[{label:"Best Streak",value:"15d",icon:"🔥",color:"#FF8C42"},{label:"This Week",value:"84%",icon:"📊",color:"#00E5C8"},{label:"Total Wins",value:"247",icon:"⚡",color:"#6450FF"}].map((s,i)=>(
      <div key={i} style={{background:"rgba(255,255,255,.04)",border:"1px solid rgba(255,255,255,.07)",borderRadius:18,padding:"14px 12px",textAlign:"center"}}>
        <div style={{fontSize:20,marginBottom:4}}>{s.icon}</div>
        <div style={{color:s.color,fontSize:18,fontWeight:800,fontFamily:"'Space Grotesk',sans-serif"}}>{s.value}</div>
        <div style={{color:"rgba(255,255,255,.35)",fontSize:10,marginTop:2}}>{s.label}</div>
      </div>
    ))}
  </div>

  {/* Habit preview */}
  <div style={{marginBottom:16}}>
    <div style={{display:"flex",justifyContent:"space-between",marginBottom:12}}>
      <span style={{color:"#fff",fontWeight:700,fontSize:15}}>Today's Habits</span>
      <span style={{color:"#00E5C8",fontSize:13,fontWeight:600}}>See all →</span>
    </div>
    {habits.slice(0,4).map((h,i)=>(
      <div key={i} className="row" style={{display:"flex",alignItems:"center",gap:12,background:"rgba(255,255,255,.03)",borderRadius:16,padding:"12px 14px",border:"1px solid rgba(255,255,255,.05)",marginBottom:8,cursor:"pointer"}}>
        <span style={{fontSize:18}}>{h.emoji}</span>
        <span style={{flex:1,color:"#fff",fontSize:14,fontWeight:500}}>{h.name}</span>
        <div style={{width:22,height:22,borderRadius:8,background:[0,1,2].includes(i)?"#00E5C8":"transparent",border:[0,1,2].includes(i)?"none":"2px solid rgba(255,255,255,.2)",display:"flex",alignItems:"center",justifyContent:"center"}}>
          {[0,1,2].includes(i)&&<span style={{color:"#000",fontSize:13,fontWeight:900}}>✓</span>}
        </div>
      </div>
    ))}
  </div>

  {/* Mindset CTA */}
  <div style={{background:"rgba(100,80,255,.12)",border:"1px solid rgba(100,80,255,.2)",borderRadius:20,padding:16,display:"flex",alignItems:"center",gap:14}}>
    <span style={{fontSize:28}}>🧘</span>
    <div style={{flex:1}}>
      <p style={{color:"#fff",fontWeight:700,fontSize:14}}>Mindset Check-in</p>
      <p style={{color:"rgba(255,255,255,.4)",fontSize:12}}>How's your energy today?</p>
    </div>
    <div style={{background:"#6450FF",borderRadius:12,padding:"8px 14px",color:"#fff",fontSize:12,fontWeight:700,cursor:"pointer"}}>Log now</div>
  </div>
</div>
```

);
}

/* ─── HABITS ─── */
function HabitsScreen({ checkedHabits, toggleHabit }) {
return (
<div style={{padding:“0 20px 20px”}}>
<div style={{paddingTop:8,marginBottom:20}}>
<p style={{color:“rgba(255,255,255,.4)”,fontSize:13}}>March 2026</p>
<h1 style={{color:”#fff”,fontSize:26,fontWeight:800,fontFamily:”‘Space Grotesk’,sans-serif”}}>Habit Tracker</h1>
</div>

```
  {/* Heatmap */}
  <div style={{background:"rgba(255,255,255,.03)",border:"1px solid rgba(255,255,255,.07)",borderRadius:24,padding:16,marginBottom:16}}>
    <div style={{display:"flex",justifyContent:"space-between",marginBottom:12}}>
      <span style={{color:"#fff",fontWeight:700,fontSize:14}}>Monthly Heatmap</span>
      <span style={{color:"#00E5C8",fontSize:12,fontWeight:600}}>87% this month</span>
    </div>
    <div style={{display:"flex",justifyContent:"space-between",marginBottom:6}}>
      {weekDays.map((d,i)=><span key={i} style={{color:"rgba(255,255,255,.3)",fontSize:10,width:32,textAlign:"center"}}>{d}</span>)}
    </div>
    <div style={{display:"grid",gridTemplateColumns:"repeat(7,1fr)",gap:4}}>
      {heatmapData.map((d,i)=>(
        <div key={i} style={{width:"100%",paddingTop:"100%",borderRadius:6,
          background:d.done?(d.partial?"rgba(0,229,200,.65)":"#00E5C8"):"rgba(255,255,255,.06)",
          boxShadow:d.done?"0 0 6px rgba(0,229,200,.3)":"none"}}/>
      ))}
    </div>
  </div>

  {/* Habit list */}
  {habits.map((h,i)=>(
    <div key={i} className="row" onClick={()=>toggleHabit(i)} style={{
      display:"flex",alignItems:"center",gap:14,
      background:"rgba(255,255,255,.04)",borderRadius:20,padding:"14px 16px",marginBottom:10,cursor:"pointer",
      border:checkedHabits.includes(i)?"1px solid rgba(0,229,200,.25)":"1px solid rgba(255,255,255,.06)",
      transition:"all .2s",
    }}>
      <div style={{width:44,height:44,borderRadius:14,background:checkedHabits.includes(i)?"rgba(0,229,200,.15)":"rgba(255,255,255,.06)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:20}}>{h.emoji}</div>
      <div style={{flex:1}}>
        <p style={{color:"#fff",fontWeight:600,fontSize:15}}>{h.name}</p>
        <p style={{color:"rgba(255,255,255,.35)",fontSize:12}}>🔥 {h.streak} day streak</p>
      </div>
      <div style={{width:28,height:28,borderRadius:10,background:checkedHabits.includes(i)?"#00E5C8":"transparent",border:checkedHabits.includes(i)?"none":"2px solid rgba(255,255,255,.2)",display:"flex",alignItems:"center",justifyContent:"center",boxShadow:checkedHabits.includes(i)?"0 0 12px rgba(0,229,200,.5)":"none",transition:"all .2s"}}>
        {checkedHabits.includes(i)&&<span style={{color:"#000",fontSize:14,fontWeight:900}}>✓</span>}
      </div>
    </div>
  ))}
</div>
```

);
}

/* ─── TASKS ─── */
function TasksScreen({ checkedTasks, toggleTask }) {
return (
<div style={{padding:“0 20px 20px”}}>
<div style={{paddingTop:8,marginBottom:8}}>
<p style={{color:“rgba(255,255,255,.4)”,fontSize:13}}>Friday</p>
<h1 style={{color:”#fff”,fontSize:26,fontWeight:800,fontFamily:”‘Space Grotesk’,sans-serif”}}>Task List</h1>
</div>

```
  {/* Progress */}
  <div style={{marginBottom:20}}>
    <div style={{display:"flex",justifyContent:"space-between",marginBottom:8}}>
      <span style={{color:"rgba(255,255,255,.5)",fontSize:12}}>{checkedTasks.length} of {tasks.length} completed</span>
      <span style={{color:"#00E5C8",fontSize:12,fontWeight:600}}>{Math.round(checkedTasks.length/tasks.length*100)}%</span>
    </div>
    <div style={{height:6,background:"rgba(255,255,255,.08)",borderRadius:3}}>
      <div style={{height:"100%",width:`${checkedTasks.length/tasks.length*100}%`,background:"linear-gradient(90deg,#00E5C8,#6450FF)",borderRadius:3,transition:"width .4s ease",boxShadow:"0 0 10px rgba(0,229,200,.4)"}}/>
    </div>
  </div>

  {/* Top 3 */}
  <div style={{background:"rgba(0,229,200,.08)",border:"1px solid rgba(0,229,200,.15)",borderRadius:20,padding:16,marginBottom:16}}>
    <p style={{color:"#00E5C8",fontWeight:700,fontSize:12,letterSpacing:1,marginBottom:12}}>⚡ TOP 3 PRIORITIES</p>
    {tasks.slice(0,3).map((t,i)=>(
      <div key={i} onClick={()=>toggleTask(i)} style={{display:"flex",alignItems:"center",gap:12,padding:"10px 0",borderBottom:i<2?"1px solid rgba(255,255,255,.05)":"none",cursor:"pointer"}}>
        <div style={{width:24,height:24,borderRadius:8,flexShrink:0,background:checkedTasks.includes(i)?"#00E5C8":"transparent",border:checkedTasks.includes(i)?"none":"2px solid rgba(255,255,255,.2)",display:"flex",alignItems:"center",justifyContent:"center",boxShadow:checkedTasks.includes(i)?"0 0 10px rgba(0,229,200,.4)":"none"}}>
          {checkedTasks.includes(i)&&<span style={{color:"#000",fontSize:12,fontWeight:900}}>✓</span>}
        </div>
        <span style={{color:checkedTasks.includes(i)?"rgba(255,255,255,.35)":"#fff",fontSize:14,fontWeight:500,textDecoration:checkedTasks.includes(i)?"line-through":"none",transition:"all .2s"}}>{t.text}</span>
      </div>
    ))}
  </div>

  {/* Other */}
  <p style={{color:"rgba(255,255,255,.35)",fontSize:12,fontWeight:600,letterSpacing:.8,marginBottom:10}}>OTHER TASKS</p>
  {tasks.slice(3).map((t,i)=>(
    <div key={i} className="row" onClick={()=>toggleTask(i+3)} style={{display:"flex",alignItems:"center",gap:12,background:"rgba(255,255,255,.03)",borderRadius:16,padding:"12px 14px",border:"1px solid rgba(255,255,255,.06)",marginBottom:8,cursor:"pointer"}}>
      <div style={{width:22,height:22,borderRadius:7,flexShrink:0,background:checkedTasks.includes(i+3)?"#00E5C8":"transparent",border:checkedTasks.includes(i+3)?"none":"2px solid rgba(255,255,255,.15)",display:"flex",alignItems:"center",justifyContent:"center"}}>
        {checkedTasks.includes(i+3)&&<span style={{color:"#000",fontSize:11,fontWeight:900}}>✓</span>}
      </div>
      <span style={{flex:1,color:checkedTasks.includes(i+3)?"rgba(255,255,255,.3)":"#fff",fontSize:14}}>{t.text}</span>
      <span style={{color:"rgba(255,255,255,.2)",fontSize:11}}>{t.category}</span>
    </div>
  ))}
</div>
```

);
}

/* ─── MINDSET ─── */
function MindsetScreen({ data }) {
const [sel, setSel] = useState(3);
return (
<div style={{padding:“0 20px 20px”}}>
<div style={{paddingTop:8,marginBottom:20}}>
<p style={{color:“rgba(255,255,255,.4)”,fontSize:13}}>This week</p>
<h1 style={{color:”#fff”,fontSize:26,fontWeight:800,fontFamily:”‘Space Grotesk’,sans-serif”}}>Mindset Tracker</h1>
</div>

```
  {/* Sliders */}
  <div style={{background:"linear-gradient(135deg,rgba(100,80,255,.2),rgba(0,229,200,.1))",border:"1px solid rgba(100,80,255,.25)",borderRadius:24,padding:20,marginBottom:16}}>
    <p style={{color:"#fff",fontWeight:700,fontSize:15,marginBottom:16}}>Today's Check-in</p>
    {[{label:"Energy",value:78,color:"#FF8C42"},{label:"Focus",value:85,color:"#00E5C8"},{label:"Mood",value:70,color:"#6450FF"}].map((m,i)=>(
      <div key={i} style={{marginBottom:14}}>
        <div style={{display:"flex",justifyContent:"space-between",marginBottom:6}}>
          <span style={{color:"rgba(255,255,255,.6)",fontSize:13}}>{m.label}</span>
          <span style={{color:m.color,fontSize:13,fontWeight:700}}>{m.value}%</span>
        </div>
        <div style={{height:8,background:"rgba(255,255,255,.08)",borderRadius:4}}>
          <div style={{height:"100%",width:`${m.value}%`,background:m.color,borderRadius:4,boxShadow:`0 0 8px ${m.color}60`}}/>
        </div>
      </div>
    ))}
  </div>

  {/* Day rings */}
  <div style={{display:"flex",justifyContent:"space-between",marginBottom:16}}>
    {data.map((d,i)=>(
      <div key={i} onClick={()=>setSel(i)} style={{display:"flex",flexDirection:"column",alignItems:"center",gap:4,cursor:"pointer"}}>
        <Ring pct={Math.round((d.energy+d.focus+d.mood)/3)} size={sel===i?48:40} stroke={sel===i?6:5} color={sel===i?"#00E5C8":"rgba(255,255,255,.25)"}/>
        <span style={{color:sel===i?"#00E5C8":"rgba(255,255,255,.3)",fontSize:11,fontWeight:600}}>{d.day}</span>
      </div>
    ))}
  </div>

  {/* Trend chart */}
  <div style={{background:"rgba(255,255,255,.03)",border:"1px solid rgba(255,255,255,.07)",borderRadius:24,padding:20}}>
    <p style={{color:"#fff",fontWeight:700,fontSize:14,marginBottom:16}}>Weekly Trends</p>
    <svg width="100%" height="80" viewBox="0 0 300 80" preserveAspectRatio="none">
      {[{vals:data.map(d=>d.energy),color:"#FF8C42"},{vals:data.map(d=>d.focus),color:"#00E5C8"},{vals:data.map(d=>d.mood),color:"#6450FF"}].map((l,li)=>{
        const pts = l.vals.map((v,i)=>`${(i/6)*300},${80-(v/100)*70}`).join(" ");
        return <polyline key={li} points={pts} fill="none" stroke={l.color} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{filter:`drop-shadow(0 0 4px ${l.color})`}}/>;
      })}
    </svg>
    <div style={{display:"flex",gap:16,marginTop:12,justifyContent:"center"}}>
      {[["Energy","#FF8C42"],["Focus","#00E5C8"],["Mood","#6450FF"]].map(([label,color])=>(
        <div key={label} style={{display:"flex",alignItems:"center",gap:6}}>
          <div style={{width:20,height:3,background:color,borderRadius:2}}/>
          <span style={{color:"rgba(255,255,255,.4)",fontSize:11}}>{label}</span>
        </div>
      ))}
    </div>
  </div>
</div>
```

);
}