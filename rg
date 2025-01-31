import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class MinimalInterpreter2 {
    
    private final Map<String, String> stringss = new HashMap<>(); // this is to store strings from python code
    private final Map<String, Boolean> booleans = new HashMap<>(); // this is for store vooleans from python code
    private final Map<String, Double> numbervars = new HashMap<>(); // and this  for store numbers from python code
    

    public void eval(String python_) {
        String[] lines = python_.split("\n"); // Split by lines

        for (int i = 0; i < lines.length; i++) {
            String line = lines[i].trim();

            if (line.isEmpty()) continue; 



            // Handle variable assignment and also check if it is not a logical not operation != and == too
            if (line.contains("=") && (!line.contains("!") && !line.contains("==")&&!line.contains("<")&&!line.contains(">"))) {
                handleAssignment(line);
            } else if (line.startsWith("print")) {
                handlePrint(line); // this is for frinting when the line strarts with it
            } else if (line.contains("while")) {
                i = handleWhileLoop(lines, i);
            } else if(line.contains("if")){
                i = handleIfElse(lines,i);
            }

        }
    }

    private void handleAssignment(String line) {
        String[] parts = line.split("="); // there line splits variable assignment by = operator into variables
        String varName = parts[0].trim(); // this helps getting variable name by the first component of parts
        String expression = parts[1].trim(); 

        if ((expression.startsWith("'") && expression.endsWith("'")) || (expression.startsWith("\"") && expression.endsWith("\""))) { // while reading string with whitespace  it will just print it without it
            String value = expression.replaceAll("'","").replaceAll("\"", "");
            stringss.put(varName, value); //this  stores variable name and value into a map
            return;
        }

        if (expression.equals("True")) { //bollean true line variant
            booleans.put(varName, true); 
            return;
        }

        if (expression.equals("False")) { // bollean false variant
            booleans.put(varName, false); 
            return;
        }

        double value = evaluateExpression(expression); 
        numbervars.put(varName, value);

    }

    // this is for numbers 
    private double evaluateExpression(String expression) {
        String[] operands = expression.split("[+\\-*/%]"); // this splits expression using operators
        double result = 0;

        try {
            result = Double.parseDouble(operands[0].trim()); // there we are  parsing the first operand as a number
        } catch (NumberFormatException e) {
            if (numbervars.containsKey(operands[0].trim())) {
                result = numbervars.get(operands[0].trim()); // Retrieve the value of the variable
            } else {
                throw new IllegalArgumentException("Undefined variable: " + operands[0].trim());
            }
        }

        // there we  try to iterate through the expression and apply operators
        int operatorIndex = 0;
        for (int i = 1; i < operands.length; i++) {
            double nextOperand = 0;  
            
            char operator = expression.charAt(expression.indexOf(operands[i-1]) + operands[i-1].length()); // 

            try {
                nextOperand = Double.parseDouble(operands[i].trim());
            } catch (NumberFormatException e) {
                if (numbervars.containsKey(operands[i].trim())) {
                    nextOperand = numbervars.get(operands[i].trim());
                } else {
                    throw new IllegalArgumentException("Undefined variable: " + operands[i].trim());
                }
            }

            // we are finding  operators and then evaluating it
            switch (operator) {
                case '+': result += nextOperand; break;
                case '-': result -= nextOperand; break;
                case '*': result *= nextOperand; break;
                case '/': result /= nextOperand; break;
                case '%': result %= nextOperand; break;
            }
        }
        return result;
    }


    private String evalString(String expression) {
        String[] stringParts = expression.split("[+\\-,]"); // split expression
        StringBuilder builder = new StringBuilder(); // we  use string builder to create a string
        for (String s : stringParts){
            if (s.startsWith("'")&&!s.trim().equals("'")){ // to remove quotations, just replace all of it with whitespace and then trim by it
                builder.append(s.replaceAll("'", "").trim());
            } else if (stringss.containsKey(s.trim())){ // if  there is a variable in stringss that has a value then append its value to a builder so you cn print that value
                builder.append(stringss.get(s.trim()));
            } else if (s.trim().equals("'")){ 
                builder.append(" ");
            } else {
                builder.append(numbervars.get(s.trim()));
            }
        }
        return builder.toString();
    }


    private int handleIfElse(String[] lines, int i) {
        String condition = lines[i].trim().substring(2);
        condition = condition.substring(0, condition.indexOf(":")).trim();

        boolean conditionResult = evalBool(condition);
        int j = i + 1;
        while (j < lines.length && lines[j].startsWith("    ")) {
            if (lines[j].contains("else"))break;
            j++;
        }

        if (conditionResult) {
            eval(String.join("\n", Arrays.copyOfRange(lines, i + 1, j)));
        }
        if (j < lines.length && lines[j].trim().startsWith("else")) {
            int k = j + 1;
            while (k < lines.length && lines[k].startsWith("    ")) {
                k++;
            }
            if (!conditionResult) eval(String.join("\n", Arrays.copyOfRange(lines, j + 1, k)));
            j = k;
        }

        return j - 1;
    }

    private int handleWhileLoop(String[] lines, int i) {
        //  the condition from the "while" line
        String condition = lines[i].substring(5).trim();
        condition = condition.substring(0, condition.indexOf(":")).trim();

        // for the loop
        int j = i + 1;
        while (j < lines.length && (lines[j].startsWith("    ")||lines[j].equals(""))) {
            j++;
        }

        // while its true it will continue
        while (evalBool(condition)) {
            eval(String.join("\n", Arrays.copyOfRange(lines, i + 1, j)));
        }

        return j - 1; 
    }

    private boolean evalBool(String expression) {
        if (booleans.containsKey(expression.trim())) return booleans.get(expression.trim());
        boolean result = true;

        if (expression.contains("and") || expression.contains("or")) {
            String[] parts = expression.split("and||or");
            result = evalBool(parts[0].trim());

            for (int i = 0; i < parts.length-1; i++) {
                parts[i] = parts[i].trim();
                String operator = expression.substring(expression.indexOf(parts[i])+parts[i].length(),expression.indexOf(parts[i+1])).trim();
                if (parts[i].charAt(0) == '!'){
                    result = switch (operator) {
                        case "and" -> result && !evalBool(parts[i + 1]);
                        case "or" -> result || !evalBool(parts[i + 1]);
                        default -> result;
                    };
                } else {
                    result = switch (operator) {
                        case "and" -> result && evalBool(parts[i + 1]);
                        case "or" -> result || evalBool(parts[i + 1]);
                        default -> result;
                    };
                }
            }

            return result;
        }

        String[] stringParts = expression.split("!=|==|<=|>=|<|>");

        for (int i = 0; i < stringParts.length-1; i++) {
            stringParts[i] = stringParts[i].trim();
            int endIndex = 0;
            String operator = expression.substring(expression.indexOf(stringParts[i])+stringParts[i].length(),expression.indexOf(stringParts[i+1])).trim();

            result = switch (operator) {
                case "=" -> evaluateExpression(stringParts[i]) == evaluateExpression(stringParts[i + 1]);
                case "<" -> evaluateExpression(stringParts[i]) < evaluateExpression(stringParts[i + 1]);
                case ">" -> evaluateExpression(stringParts[i]) > evaluateExpression(stringParts[i + 1]);
                case "!" -> evaluateExpression(stringParts[i]) != evaluateExpression(stringParts[i + 1]);
                case "<=" -> evaluateExpression(stringParts[i]) <= evaluateExpression(stringParts[i + 1]);
                case ">=" -> evaluateExpression(stringParts[i]) >= evaluateExpression(stringParts[i + 1]);
                default -> result;
            };
        }

        return result;
    }


    // checks if expression contains any stringss
    private boolean containsStringss(String expression) {
        String[] stringParts = expression.split("[+\\-,]");
        for (String s : stringParts){ // splits the expression into parts based on operators , to iterate through every part.
            if (stringss.containsKey(s.trim())) return true;
        } 
        return false;
    }

    // then if no stringss is found returns false, if it is found  returns true.
    // this mehtod handles "print" command 
    private void handlePrint(String line) {
        String varName = line.substring(line.indexOf('(') + 1, line.indexOf(')')).trim();

        // Handles String
        if ((varName.startsWith("'") && varName.endsWith("'")) || (varName.startsWith("\"") && varName.endsWith("\""))) {
            // It's a string , print it as is
            System.out.println(varName.substring(1, varName.length() - 1));  
            return;
        }

        // Handles Variable
        if (stringss.containsKey(varName)){
            System.out.println(stringss.get(varName));
            return; //// Retrieve and print the value of the stringss
        }

        if (booleans.containsKey(varName) || varName.contains("&") || varName.contains("|")
                || varName.contains("<") || varName.contains(">") || varName.contains("==") || varName.contains("!=")) {
            System.out.println(evalBool(varName));
            return; // If it's a boolean variable or contains boolean expressions, evaluate and print its value
        }
        if ((varName.contains("+") || varName.contains(",")) && containsStringss(varName)) {
            System.out.println(evalString(varName));
            return; 
        }
        String toPrint = String.valueOf(evaluateExpression(varName)); // numeric expressions
       //print the result
        System.out.println(toPrint);

    }

    public static void main(String[] args) {
        String python_ = """
                number = 5
                result = 1
                while number > 1:
                    result *= number
                    number -= 1 
                """;
                //we will write a several strings and functions like this for every algorithm

        MinimalInterpreter2 interpreter2 = new MinimalInterpreter2();
        interpreter2.eval(python_);
    }
}
